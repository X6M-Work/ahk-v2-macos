namespace Keysharp.Builtins;

public partial class OwnPropsDesc
{
	private bool ownsReferences;
	internal static OwnPropsDesc Counted() => new() { ownsReferences = true };
	internal OwnPropsDesc CopyForOwner()
	{
		var result = (OwnPropsDesc)MemberwiseClone();
		result.ownsReferences = false;
		return result;
	}
	internal OwnPropsDesc CountedCopy()
	{
		var result = CopyForOwner();
		result.ownsReferences = true;
		Lifetime.Retain(result._value);
		Lifetime.Retain(result._get);
		Lifetime.Retain(result._set);
		Lifetime.Retain(result._call);
		return result;
	}
	private void ReplaceSlots(object value, object get, object set, object call)
	{
		if (!ownsReferences)
		{
			_value = Lifetime.Escape(value);
			_get = Lifetime.Escape(get);
			_set = Lifetime.Escape(set);
			_call = Lifetime.Escape(call);
			return;
		}
		Lifetime.Retain(value);
		Lifetime.Retain(get);
		Lifetime.Retain(set);
		Lifetime.Retain(call);
		var previous = (_value, _get, _set, _call);
		(_value, _get, _set, _call) = (value, get, set, call);
		Release(previous);
	}
	internal void EscapeReferences()
	{
		if (!ownsReferences) return;
		ownsReferences = false;
		Lifetime.Escape(_value);
		Lifetime.Escape(_get);
		Lifetime.Escape(_set);
		Lifetime.Escape(_call);
	}
	internal void ReleaseReferences()
	{
		if (!ownsReferences) return;
		ownsReferences = false;
		var previous = (_value, _get, _set, _call);
		_value = _get = _set = _call = null;
		Type = OwnPropsMapType.None;
		Release(previous);
	}
	private static void Release((object value, object get, object set, object call) values)
	{
		try { Lifetime.Release(values.value); }
		finally
		{
			try { Lifetime.Release(values.get); }
			finally
			{
				try { Lifetime.Release(values.set); }
				finally { Lifetime.Release(values.call); }
			}
		}
	}
}
