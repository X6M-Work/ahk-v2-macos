using System.Linq;

namespace Keysharp.Builtins;

public partial class Any
{
	private bool ownsProperties;
	private KeyValuePair<object, object>[] enumerableProperties;
	internal bool OwnsProperties => ownsProperties;

	private void BeginPropertyReferences()
	{
		ownsProperties = true;
		enumerableProperties = null;
		if (op == null) return;
		foreach (var pair in op.ToArray()) op[pair.Key] = pair.Value.CountedCopy();
	}

	internal void AbandonOwnedReferences()
	{
		if (ownsProperties)
		{
			ownsProperties = false;
			if (op != null)
				foreach (var desc in op.Values.ToArray()) desc.EscapeReferences();
		}
		EscapeOwnedReferences();
	}

	private void ReleasePropertyReferences()
	{
		if (!ownsProperties) return;
		ownsProperties = false;
		var previous = op;
		op = null;
		enumerableProperties = null;
		if (previous != null)
			foreach (var pair in previous.OrderBy(pair => pair.Key, AhkIdentifierComparer.Instance)) pair.Value.ReleaseReferences();
	}

	internal void SetOwnDataProperty(string name, object value, bool shadow = false)
	{
		if (!ownsProperties)
		{
			if (shadow)
			{
				EnsureOwnProps()[name] = new OwnPropsDesc(value);
				enumerableProperties = null;
				OnPropertyChanged(name);
				return;
			}
			if (value == null) { DeleteOwnPropInternal(name); return; }
			DefinePropInternal(name, new OwnPropsDesc(value));
			return;
		}
		Lifetime.Retain(this);
		OwnPropsDesc staged = null;
		try
		{
			if (value == null && !shadow) { RemoveOwnedProperty(name, false); return; }
			staged = op != null && op.TryGetValue(name, out var previous) ? previous.CountedCopy() : OwnPropsDesc.Counted();
			staged.Value = value;
			var next = staged;
			staged = null;
			PublishOwnedProperty(name, next);
		}
		finally
		{
			staged?.ReleaseReferences();
			Lifetime.ReleaseScope(this);
		}
	}

	internal void MergeOwnProperty(string name, object value, object get, object set, object call, bool enumerable)
	{
		if (!ownsProperties)
		{
			DefinePropInternal(name, new OwnPropsDesc(value, get, set, call));
			op[name].Enumerable = enumerable;
			return;
		}
		Lifetime.Retain(this);
		OwnPropsDesc staged = null;
		try
		{
			staged = op != null && op.TryGetValue(name, out var previous) ? previous.CountedCopy() : OwnPropsDesc.Counted();
			staged.Enumerable = enumerable;
			var next = staged;
			staged = null;
			PublishOwnedProperty(name, next);
			// AHK exposes the new descriptor while accessor metadata is being evaluated.
			next.Merge(value, get, set, call);
			OnPropertyChanged(name);
		}
		finally
		{
			staged?.ReleaseReferences();
			Lifetime.ReleaseScope(this);
		}
	}

	private void PublishOwnedProperty(string name, OwnPropsDesc next)
	{
		if (!ownsProperties) next.EscapeReferences();
		EnsureOwnProps().TryGetValue(name, out var previous);
		op[name] = next;
		enumerableProperties = null;
		OnPropertyChanged(name);
		previous?.ReleaseReferences();
	}

	private object RemoveOwnedProperty(string name, bool transfer)
	{
		if (op == null || !op.Remove(name, out var previous)) return DefaultObject;
		if (op.Count == 0) op = null;
		enumerableProperties = null;
		var result = transfer ? Lifetime.Temporary(previous.Value) : null;
		OnPropertyChanged(name);
		previous.ReleaseReferences();
		return result;
	}

	internal KeyValuePair<object, object>[] CurrentOwnProperties() => op == null ? []
		: enumerableProperties ??= op.Where(pair => pair.Key != "__Static").OrderBy(pair => pair.Key, AhkIdentifierComparer.Instance)
		.Select(pair => new KeyValuePair<object, object>(pair.Key, pair.Value)).ToArray();
}
