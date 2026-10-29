using System.Runtime.CompilerServices;

namespace Keysharp.Runtime
{
	// Group lifetime roots so generated finally blocks stay small without allocating argument arrays.
	[PublicHiddenFromUser]
	public static partial class Lifetime
	{
		public static Keysharp.Builtins.VarRef Box(object value) => new(value, scoped: true);

		public static object Retain(object value)
		{
			if (value is Keysharp.Builtins.Any owned) owned.RetainReference();
			if (value is Keysharp.Builtins.VarRef box) box.RetainBox();
			return value;
		}

		public static void Release(object value)
		{
			if (value is Keysharp.Builtins.VarRef box) box.ReleaseBox();
			if (value is Keysharp.Builtins.Any owned) owned.ReleaseReference();
		}

		public static object Replace(ref object slot, object value)
		{
			if (ReferenceEquals(slot, value)) return value;
			Retain(value);
			Retain(value); // Protect the incoming value while the previous value's __Delete runs.
			var previous = slot;
			slot = value;
			try { Release(previous); }
			finally { Release(value); }
			return slot;
		}

		public static object Replace(Keysharp.Builtins.VarRef slot, object value) => slot.ReplaceValue(value);

		public static object Escape(object value)
		{
			if (value is Keysharp.Builtins.Any owned) owned.EscapeReferences();
			if (value is Keysharp.Builtins.VarRef reference) reference.EscapeValue();
			return value;
		}

		public static object Borrow(object value) => value is Keysharp.Builtins.Any owned
			&& (owned.ReferenceState is Keysharp.Builtins.ReferenceLifeState.Constructing or Keysharp.Builtins.ReferenceLifeState.Deleting
				|| owned.ReferenceState == Keysharp.Builtins.ReferenceLifeState.Alive && owned.HasReferences)
			|| value is Keysharp.Builtins.VarRef { HasBoxReferences: true }
			? value : Escape(value);

		public static object Return(object value) => value is Keysharp.Builtins.Any owned
			&& owned.ReferenceState is Keysharp.Builtins.ReferenceLifeState.Constructing or Keysharp.Builtins.ReferenceLifeState.Deleting
			? value : returnScope != null ? returnScope.Track(value) : Escape(value);

		[MethodImpl(MethodImplOptions.AggressiveInlining)]
		public static void ReleaseScope(object a)
		{
			if (Script.TheScript?.hasExited != true) Release(a);
			GC.KeepAlive(a);
		}

		[MethodImpl(MethodImplOptions.AggressiveInlining)]
		public static void ReleaseScope(object a, object b) { ReleaseScope(a); ReleaseScope(b); }

		[MethodImpl(MethodImplOptions.AggressiveInlining)]
		public static void ReleaseScope(object a, object b, object c) { ReleaseScope(a, b); ReleaseScope(c); }

		[MethodImpl(MethodImplOptions.AggressiveInlining)]
		public static void ReleaseScope(object a, object b, object c, object d)
		{
			ReleaseScope(a);
			ReleaseScope(b);
			ReleaseScope(c);
			ReleaseScope(d);
		}

		[MethodImpl(MethodImplOptions.AggressiveInlining)]
		public static void ReleaseScope(object a, object b, object c, object d, object e) { ReleaseScope(a, b, c, d); ReleaseScope(e); }

		[MethodImpl(MethodImplOptions.AggressiveInlining)]
		public static void ReleaseScope(object a, object b, object c, object d, object e, object f) { ReleaseScope(a, b, c, d); ReleaseScope(e, f); }

		[MethodImpl(MethodImplOptions.AggressiveInlining)]
		public static void ReleaseScope(object a, object b, object c, object d, object e, object f, object g) { ReleaseScope(a, b, c, d); ReleaseScope(e, f, g); }

		[MethodImpl(MethodImplOptions.AggressiveInlining)]
		public static void ReleaseScope(object a, object b, object c, object d, object e, object f, object g, object h) { ReleaseScope(a, b, c, d); ReleaseScope(e, f, g, h); }

		[MethodImpl(MethodImplOptions.AggressiveInlining)]
		public static void KeepAlive(object a, object b) { GC.KeepAlive(a); GC.KeepAlive(b); }

		[MethodImpl(MethodImplOptions.AggressiveInlining)]
		public static void KeepAlive(object a, object b, object c) { KeepAlive(a, b); GC.KeepAlive(c); }

		[MethodImpl(MethodImplOptions.AggressiveInlining)]
		public static void KeepAlive(object a, object b, object c, object d)
		{
			GC.KeepAlive(a);
			GC.KeepAlive(b);
			GC.KeepAlive(c);
			GC.KeepAlive(d);
		}

		[MethodImpl(MethodImplOptions.AggressiveInlining)]
		public static void KeepAlive(object a, object b, object c, object d, object e) { KeepAlive(a, b, c, d); GC.KeepAlive(e); }

		[MethodImpl(MethodImplOptions.AggressiveInlining)]
		public static void KeepAlive(object a, object b, object c, object d, object e, object f) { KeepAlive(a, b, c, d); KeepAlive(e, f); }

		[MethodImpl(MethodImplOptions.AggressiveInlining)]
		public static void KeepAlive(object a, object b, object c, object d, object e, object f, object g) { KeepAlive(a, b, c, d); KeepAlive(e, f, g); }

		[MethodImpl(MethodImplOptions.AggressiveInlining)]
		public static void KeepAlive(object a, object b, object c, object d, object e, object f, object g, object h) { KeepAlive(a, b, c, d); KeepAlive(e, f, g, h); }
	}
}
