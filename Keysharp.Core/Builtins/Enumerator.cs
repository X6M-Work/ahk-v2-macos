namespace Keysharp.Builtins
{
	public partial class Enumerator : KeysharpFunc, IEnumerator<object>, IEnumerator<(object, object)>, IDisposable
	{
		internal static readonly object True = true;
		private static readonly object False = false;
		private static MethodPropertyHolder callMethod;

		private readonly Func<bool> moveNext;
		private readonly Func<object> currentValue;
		private readonly Func<(object, object)> currentPair;
		private readonly Action reset;
		private readonly Action dispose;
		private readonly Func<bool> hasValue;
		private readonly KeysharpFunc callback;
		private readonly Map.EnumerationSnapshot snapshot;

		internal object Source { get; }
		internal bool UsesV20NativeContract { get; }

		// Zero selects adaptive arity.
		internal long Count { get; }

		internal object CurrentValue => currentValue != null ? currentValue() : currentPair?.Invoke().Item1;

		private (object, object) CurrentPair => currentPair?.Invoke() ?? (currentValue?.Invoke(), null);

		// Keep iteration plumbing off the script surface.
		object IEnumerator<object>.Current => CurrentValue;

		(object, object) IEnumerator<(object, object)>.Current => CurrentPair;

		object IEnumerator.Current => CurrentValue;

		public Enumerator(params object[] args) : base(args)
		{
		}

		// Iteration disposal and release of the retained source have separate lifetimes.
		internal override bool DisposesWhenCollected => ownsSource;

		internal Enumerator(
			object source,
			int count,
			Func<bool> moveNext,
			Func<object> currentValue,
			Func<(object, object)> currentPair,
			Action reset,
			Action dispose = null,
			Func<bool> hasValue = null,
			Map.EnumerationSnapshot snapshot = null)
			: base(CallMethod(), null)
		{
			if (Base == null)
				InitializeBase(typeof(Enumerator));

			Source = source;
			UsesV20NativeContract = Script.CompatV20 && moveNext != null
				&& (hasValue != null || source is Array or RegExMatchInfo || source is Map and not Ks.HashMap);
			Count = UsesV20NativeContract ? count : Math.Max(0, count);
			Inst = this;
			if (UsesV20NativeContract)
			{
				MinParams = 0;
				MaxParams = count;
			}
			this.moveNext = moveNext;
			this.currentValue = currentValue;
			this.currentPair = currentPair;
			this.reset = reset;
			this.dispose = dispose;
			this.hasValue = hasValue;
			this.snapshot = snapshot;
		}

		internal Enumerator(object source, int count, KeysharpFunc callback)
			: this(source, count, null, null, null, null)
		{
			this.callback = callback;
		}

		private static MethodPropertyHolder CallMethod() => callMethod ??= Reflections.FindAndCacheMethod(typeof(Enumerator), nameof(Call), 1);

		public override bool IsByRef(object paramIndex = null) =>
			UsesV20NativeContract && paramIndex == null ? MaxParams > 0 : base.IsByRef(paramIndex);

		// OwnProps must not evaluate getters during name-only enumeration.
		internal bool Advance(long requested)
		{
			while (moveNext?.Invoke() == true)
				if (requested < 2 || hasValue == null || hasValue())
					return true;

			return false;
		}

		bool IEnumerator.MoveNext() => Advance(Count == 0 ? 2 : Count);

		void IEnumerator.Reset() => reset?.Invoke();

		void IDisposable.Dispose() => dispose?.Invoke();

		public override object Call([ByRef] params object[] args)
		{
			var owned = ownsSource;
			if (owned) Lifetime.Retain(this);
			try
			{
				if (callback != null)
					return callback.Call(args);
				if (UsesV20NativeContract)
					return CallV20(args);

				var argumentCount = args?.Length ?? 0;

				if (argumentCount > 2 || Count != 0 && argumentCount != Count)
					return Errors.ErrorOccurred(new ArgumentError($"Enumerator.Call expects {(Count == 0 ? "at most 2" : Count.ToString())} output arguments."), False);

				var first = argumentCount > 0 ? args[0] : null;
				var second = argumentCount > 1 ? args[1] : null;
				if (first != null && !Refs.IsRef(first))
					return Errors.ExpectedTypeErrorOccurred("variable reference", first, False);
				if (second != null && !Refs.IsRef(second))
					return Errors.ExpectedTypeErrorOccurred("variable reference", second, False);

				if (!Advance(second == null ? 1 : 2))
				{
					((IDisposable)this).Dispose();
					return False;
				}

				if (second != null)
				{
					var pair = CurrentPair;
					AssignPair(first, second, pair);
				}
				else if (first != null)
					Refs.SetValue(first, CurrentValue);

				return True;
			}
			catch (Exception e) when (e is not KeysharpException && !Keysharp.Internals.Flow.TryGetException<Flow.UserRequestedExitException>(e, out _))
			{
				return Errors.ErrorOccurred(e.Message);
			}
			finally { if (owned) Lifetime.ReleaseScope(this); }
		}

		private void AssignPair(object first, object second, (object, object) pair)
		{
			Lifetime.Retain(pair.Item1);
			try
			{
				Lifetime.Retain(pair.Item2);
				try
				{
					Refs.SetValue(first, pair.Item1);
					Refs.SetValue(second, pair.Item2);
				}
				finally { Lifetime.Release(pair.Item2); }
			}
			finally { Lifetime.Release(pair.Item1); }
		}

		private object CallV20(object[] args)
		{
			var argumentCount = args?.Length ?? 0;
			var pairMode = hasValue != null || Source is Map ? argumentCount > 1
				: Count == 0 ? argumentCount > 1 && args[1] is VarRef
				: Source is Array ? Count > 1 : Count != 1;
			var first = argumentCount > 0 ? args[0] as VarRef : null;
			var second = pairMode && argumentCount > 1 ? args[1] as VarRef : null;

			if (!Advance(second != null ? 2 : 1))
			{
				((IDisposable)this).Dispose();
				return False;
			}

			if (pairMode && (second != null || first != null && hasValue == null))
			{
				var pair = CurrentPair;
				AssignPair(first, second, pair);
			}
			else if (first != null)
				Refs.SetValue(first, CurrentValue);

			return True;
		}
	}
}
