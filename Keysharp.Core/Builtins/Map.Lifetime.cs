using System.Linq;

namespace Keysharp.Builtins;

public partial class Map
{
	private bool ownsEntries;
	private int mutationVersion;
	internal bool OwnsEntries => ownsEntries;
	internal override bool SupportsOwnedReferences => GetType() == typeof(Map);
	internal override bool DisposesWhenCollected => ownsEntries || base.DisposesWhenCollected;

	internal override void BeginOwnedReferences()
	{
		ownsEntries = true;
		foreach (var pair in map)
		{
			Lifetime.Retain(pair.Key);
			Lifetime.Retain(pair.Value);
		}
	}

	internal override void ResetOwnedReferences() => ownsEntries = false;

	internal override void EscapeOwnedReferences()
	{
		if (!ownsEntries) return;
		ownsEntries = false;
		foreach (var pair in map.ToArray())
		{
			Lifetime.Escape(pair.Key);
			Lifetime.Escape(pair.Value);
		}
	}

	internal override void ReleaseOwnedReferences()
	{
		if (!ownsEntries) return;
		ownsEntries = false;
		var previous = SortedPairs();
		map.Clear();
		enumerableMap = null;
		ReleasePairs(previous);
	}

	[PublicHiddenFromUser]
	public new static Map OwnedLiteral(params object[] pairs)
	{
		var result = new Map(eCaseSense.On);
		result.BeginReferenceConstruction();
		try { result.Set(pairs); }
		finally
		{
			result.CompleteReferenceConstruction();
			Lifetime.Temporary(result);
		}
		return result;
	}

	private KeyValuePair<object, object>[] SortedPairs()
	{
		var pairs = map.ToArray();
		if (mapComparer == null || mapComparer.CaseSense != caseSense) mapComparer = new MapComparer(caseSense);
		if (pairs.Length > 1) System.Array.Sort(pairs, mapComparer);
		return pairs;
	}

	private static void ReleasePairs(KeyValuePair<object, object>[] pairs)
	{
		for (var i = pairs.Length - 1; i >= 0; i--)
			try { Lifetime.Release(pairs[i].Value); }
			finally { Lifetime.Release(pairs[i].Key); }
	}

	private void ClearEntries()
	{
		while (map.Count != 0)
		{
			if (!ownsEntries) { map.Clear(); enumerableMap = null; mutationVersion++; return; }
			var pairs = SortedPairs();
			for (var i = pairs.Length - 1; i >= 0; i--)
			{
				map.Remove(pairs[i].Key);
				enumerableMap = null;
				var version = ++mutationVersion;
				try { Lifetime.Release(pairs[i].Value); }
				finally { Lifetime.Release(pairs[i].Key); }
				if (version != mutationVersion || !ownsEntries) break;
			}
		}
	}

	private object StoredKey(object key)
	{
		if (key is Any or VarRef)
			foreach (var stored in map.Keys)
				if (map.Comparer.Equals(stored, key)) return stored;
		return key;
	}

	private void InsertEntry(object key, object value, bool addOnly = false)
	{
		var existed = map.TryGetValue(key, out var previous);
		if (existed && addOnly) { map.Add(key, value); return; }
		if (existed && ReferenceEquals(previous, value)) return;
		if (!ownsEntries)
		{
			Lifetime.Escape(key);
			Lifetime.Escape(value);
			map[key] = value;
			UpdateEnumeration(key, value, existed);
			return;
		}
		Lifetime.Retain(this);
		Lifetime.Retain(value);
		try
		{
			if (!existed) Lifetime.Retain(key);
			try
			{
				Lifetime.Retain(value);
				try { map[key] = value; }
				catch { Lifetime.Release(value); throw; }
			}
			catch { if (!existed) Lifetime.Release(key); throw; }
			UpdateEnumeration(key, value, existed);
			if (existed) Lifetime.Release(previous);
		}
		finally
		{
			Lifetime.Release(value);
			Lifetime.ReleaseScope(this);
		}
	}

	private void UpdateEnumeration(object key, object value, bool existed)
	{
		mutationVersion++;
		if (enumerableMap == null) return;
		var pairs = enumerableMap.Pairs;
		var i = existed && mapComparer != null ? System.Array.BinarySearch(pairs, new KeyValuePair<object, object>(key, null), mapComparer) : -1;
		if (i >= 0 && map.Comparer.Equals(pairs[i].Key, key)) enumerableMap.Replace(i, value);
		else enumerableMap = null;
	}

	private bool RemoveEntry(object key, bool transfer, out object value)
	{
		var stored = ownsEntries ? StoredKey(key) : key;
		if (!map.TryGetValue(key, out value)) return false;
		if (transfer) Lifetime.Temporary(value);
		map.Remove(key);
		enumerableMap = null;
		mutationVersion++;
		if (ownsEntries)
			try { Lifetime.Release(value); }
			finally { Lifetime.Release(stored); }
		return true;
	}

	private void AdoptStorage(Dictionary<object, object> replacement, Map source = null)
	{
		if (ReferenceEquals(map, replacement)) return;
		var previous = ownsEntries ? SortedPairs() : null;
		// External dictionary aliases cannot participate in entry reference counts.
		if (source != null) Lifetime.Escape(source);
		foreach (var pair in replacement.ToArray())
		{
			Lifetime.Escape(pair.Key);
			Lifetime.Escape(pair.Value);
		}
		ownsEntries = false;
		map = replacement;
		enumerableMap = null;
		mapComparer = null;
		mutationVersion++;
		if (source != null) caseSense = source.caseSense;
		if (previous != null) ReleasePairs(previous);
	}

	private Enumerator PrepareEnumerator(Enumerator result)
	{
		result.BeginReferenceConstruction();
		result.CompleteReferenceConstruction();
		return (Enumerator)Lifetime.Temporary(result);
	}

	internal sealed class EnumerationSnapshot
	{
		internal readonly KeyValuePair<object, object>[] Pairs;
		private int users;
		private bool owned;
		internal EnumerationSnapshot(KeyValuePair<object, object>[] pairs, bool owned) { Pairs = pairs; this.owned = owned; }
		internal void Retain()
		{
			if (users++ != 0 || !owned) return;
			foreach (var pair in Pairs) { Lifetime.Retain(pair.Key); Lifetime.Retain(pair.Value); }
		}
		internal void Release()
		{
			if (--users == 0 && owned) ReleasePairs(Pairs.ToArray());
		}
		internal void Escape()
		{
			if (!owned) return;
			owned = false;
			foreach (var pair in Pairs) { Lifetime.Escape(pair.Key); Lifetime.Escape(pair.Value); }
		}
		internal void Replace(int index, object value)
		{
			var pair = Pairs[index];
			var retained = owned && users > 0;
			if (retained) Lifetime.Retain(value);
			Pairs[index] = new(pair.Key, value);
			if (retained) Lifetime.Release(pair.Value);
		}
	}
}
