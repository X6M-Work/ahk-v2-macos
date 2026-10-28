using Keysharp.Builtins;

namespace Keysharp.Runtime
{
	[PublicHiddenFromUser]
	public sealed class LocalFileScope : IDisposable
	{
		[ThreadStatic] private static LocalFileScope current;
		private readonly LocalFileScope parent = current;
		private readonly Script owner = Script.TheScript;
		private readonly List<KeysharpFile> files = [];
		private bool escaped, disposed;

		public LocalFileScope() => current = this;

		public object Track(object value)
		{
			if (value is KeysharpFile file && file.GetType() == typeof(KeysharpFile) && file.Stream != null)
				files.Add(file);
			return value;
		}

		internal static void ObserveCall(Type declaringType, object instance, object[] arguments)
		{
			if (current == null || declaringType == typeof(KeysharpFile))
				return;
			if (declaringType?.Assembly == typeof(KeysharpFile).Assembly
				&& instance is not KeysharpFile && !(arguments?.Any(value => value is KeysharpFile) ?? false))
				return;
			// User code and rebound methods can retain a receiver through paths the lexical proof cannot see.
			for (var scope = current; scope != null; scope = scope.parent)
				scope.escaped = true;
		}

		public void Dispose()
		{
			if (disposed)
				return;
			disposed = true;
			current = parent;
			if (!escaped && !owner.hasExited)
				for (var i = files.Count - 1; i >= 0; i--)
					if (!files[i].HasDeleteCall)
					{
						try { ((IDisposable)files[i]).Dispose(); }
						catch (Exception error) { _ = Keysharp.Internals.Diagnostics.Debug.WriteLine(error.Message); }
					}
			files.Clear();
		}
	}
}
