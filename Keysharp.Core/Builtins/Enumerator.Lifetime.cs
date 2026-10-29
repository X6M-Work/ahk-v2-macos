namespace Keysharp.Builtins;

public partial class Enumerator
{
	private bool ownsSource;
	internal bool OwnsSource => ownsSource;
	internal override bool SupportsOwnedReferences => GetType() == typeof(Enumerator) && moveNext != null && Source is Array { OwnsElements: true };
	internal override void BeginOwnedReferences()
	{
		ownsSource = true;
		Keysharp.Runtime.Lifetime.Retain(Source);
	}
	internal override void ResetOwnedReferences() => ownsSource = false;
	internal override void EscapeOwnedReferences()
	{
		if (!ownsSource) return;
		ownsSource = false;
		Keysharp.Runtime.Lifetime.Escape(Source);
	}
	internal override void ReleaseOwnedReferences()
	{
		if (!ownsSource) return;
		ownsSource = false;
		Keysharp.Runtime.Lifetime.Release(Source);
	}
}
