namespace Keysharp.Builtins;

public partial class Array
{
	private bool ownsElements;
	internal override bool SupportsOwnedReferences => GetType() == typeof(Array);
	internal override bool DisposesWhenCollected => ownsElements || base.DisposesWhenCollected;
	internal bool OwnsElements => ownsElements;

	internal override void BeginOwnedReferences()
	{
		ownsElements = true;
		foreach (var value in array) Keysharp.Runtime.Lifetime.Retain(value);
	}

	internal override void ResetOwnedReferences() => ownsElements = false;

	internal override void EscapeOwnedReferences()
	{
		if (!ownsElements) return;
		ownsElements = false;
		foreach (var value in array.ToArray()) Keysharp.Runtime.Lifetime.Escape(value);
	}

	internal override void ReleaseOwnedReferences()
	{
		if (!ownsElements) return;
		ownsElements = false;
		var previous = array;
		array = new();
		foreach (var value in previous) Keysharp.Runtime.Lifetime.Release(value);
	}

	[PublicHiddenFromUser]
	public static Array OwnedLiteral(params object[] items)
	{
		var result = new Array(null);
		result.BeginReferenceConstruction();
		result.array.Capacity = Math.Max(result.capacity, items?.Length ?? 0);
		if (items != null)
			foreach (var value in items) result.array.Add(result.StoreValue(value));
		result.CompleteReferenceConstruction();
		return (Array)Keysharp.Runtime.Lifetime.Temporary(result);
	}

	private object StoreValue(object value) => ownsElements
		? Keysharp.Runtime.Lifetime.Retain(value) : Keysharp.Runtime.Lifetime.Escape(value);

	internal void SetItem(int index, object value)
	{
		if (ReferenceEquals(array[index], value)) return;
		if (!ownsElements) { array[index] = Keysharp.Runtime.Lifetime.Escape(value); return; }
		Keysharp.Runtime.Lifetime.Retain(this);
		Keysharp.Runtime.Lifetime.Retain(value);
		Keysharp.Runtime.Lifetime.Retain(value);
		var previous = array[index];
		array[index] = value;
		try { Keysharp.Runtime.Lifetime.Release(previous); }
		finally
		{
			Keysharp.Runtime.Lifetime.Release(value);
			Keysharp.Runtime.Lifetime.ReleaseScope(this);
		}
	}

	private void RemoveItems(int index, int count)
	{
		var owned = ownsElements;
		var previous = owned ? array.GetRange(index, count) : null;
		array.RemoveRange(index, count);
		if (previous != null)
			foreach (var value in previous) Keysharp.Runtime.Lifetime.Release(value);
	}

	private object RemoveValue(int index, bool leaveHole)
	{
		var owned = ownsElements;
		var previous = Keysharp.Runtime.Lifetime.Temporary(array[index]);
		if (leaveHole) array[index] = null;
		else array.RemoveAt(index);
		if (owned) Keysharp.Runtime.Lifetime.Release(previous);
		return previous ?? DefaultObject;
	}

	private void AppendItems(IEnumerable<object> values)
	{
		var owned = ownsElements;
		var replacement = new List<object>();
		try { foreach (var value in values) replacement.Add(StoreValue(value)); }
		catch
		{
			if (owned) foreach (var value in replacement) Keysharp.Runtime.Lifetime.Release(value);
			throw;
		}
		try { array.AddRange(replacement); }
		catch
		{
			if (owned) foreach (var value in replacement) Keysharp.Runtime.Lifetime.Release(value);
			throw;
		}
		if (array.Count < capacity) array.EnsureCapacity(capacity);
	}
}
