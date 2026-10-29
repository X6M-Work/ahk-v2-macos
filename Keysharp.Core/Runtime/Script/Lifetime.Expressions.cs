namespace Keysharp.Runtime
{
	public static partial class Lifetime
	{
		[ThreadStatic] private static ExpressionScope expressionScope;
		[ThreadStatic] private static ExpressionScope returnScope;

		public static ExpressionScope BeginExpression() => new();

		public static T Evaluate<T>(Func<T> evaluate)
		{
			using var scope = BeginExpression();
			return evaluate();
		}

		public static object Temporary(object value) => expressionScope != null ? expressionScope.Track(value) : Escape(value);

		internal static InvocationScope EnterInvocation() => new();

		internal readonly struct InvocationScope : IDisposable
		{
			private readonly ExpressionScope previous;
			public InvocationScope()
			{
				previous = returnScope;
				returnScope = expressionScope;
			}
			public void Dispose() => returnScope = previous;
		}

		[PublicHiddenFromUser]
		public sealed class ExpressionScope : IDisposable
		{
			private readonly ExpressionScope parent;
			private List<object> values;
			private bool disposed;

			internal ExpressionScope()
			{
				parent = expressionScope;
				expressionScope = this;
			}

			internal object Track(object value)
			{
				if (value is not Keysharp.Builtins.Any { ReferenceState: Keysharp.Builtins.ReferenceLifeState.Alive
					or Keysharp.Builtins.ReferenceLifeState.Resurrected }
					&& value is not Keysharp.Builtins.VarRef { HasBoxReferences: true }) return Escape(value);
				if (values != null && values.Exists(item => ReferenceEquals(item, value))) return value;
				Retain(value);
				(values ??= []).Add(value);
				return value;
			}

			public void Dispose()
			{
				if (disposed) return;
				disposed = true;
				expressionScope = parent;
				if (values == null) return;
				for (var i = values.Count - 1; i >= 0; i--)
				{
					var value = values[i];
					values[i] = null;
					ReleaseScope(value);
				}
			}
		}
	}
}
