namespace Keysharp.Builtins
{
	internal enum ReferenceLifeState { Untracked, Constructing, Alive, Deleting, Resurrected, Released }

	public partial class Any
	{
		private Lock referenceGate;
		private int referenceState;
		private long referenceCount;
		private bool referencesEscaped;
		internal ReferenceLifeState ReferenceState => (ReferenceLifeState)Volatile.Read(ref referenceState);
		internal bool HasReferences => Volatile.Read(ref referenceCount) > 0;
		internal bool AllowsCollectedCleanup => ReferenceState == ReferenceLifeState.Untracked;

		internal virtual bool SupportsOwnedReferences => false;
		internal virtual void BeginOwnedReferences() { }
		internal virtual void EscapeOwnedReferences() { }
		internal virtual void ReleaseOwnedReferences() { }
		internal virtual void ResetOwnedReferences() { }

		internal void BeginReferenceConstruction()
		{
			// Only opted-in native containers bypass script-class instrumentation.
			var root = GetType();
			if (!SupportsOwnedReferences)
			{
				if (root.Assembly == typeof(Any).Assembly) return;
				while (root != null && root.Assembly != typeof(Any).Assembly)
				{
					if (!root.IsDefined(typeof(Keysharp.Runtime.ReferenceCountedAttribute), false)) return;
					root = root.BaseType;
				}
				if (root != typeof(KeysharpObject) && root != typeof(Map) && root != typeof(Array)) return;
			}
			referenceGate = new();
			referenceState = (int)ReferenceLifeState.Constructing;
			BeginPropertyReferences();
			BeginOwnedReferences();
		}

		internal void CompleteReferenceConstruction()
		{
			if (referenceGate == null) return;
			lock (referenceGate)
				referenceState = (int)(referencesEscaped ? ReferenceLifeState.Untracked : ReferenceLifeState.Alive);
			MaybeActivateFinalizer();
		}

		internal void EscapeReferences()
		{
			if (referenceGate == null || ReferenceState == ReferenceLifeState.Untracked) return;
			lock (referenceGate)
			{
				referencesEscaped = true;
				if (ReferenceState is ReferenceLifeState.Alive or ReferenceLifeState.Resurrected)
					referenceState = (int)ReferenceLifeState.Untracked;
			}
			AbandonOwnedReferences();
		}

		internal void RetainReference()
		{
			if (referenceGate == null) return;
			lock (referenceGate)
			{
				if (ReferenceState == ReferenceLifeState.Released)
					throw new InvalidOperationException("Retaining a released script object.");
				if (ReferenceState != ReferenceLifeState.Untracked)
					referenceCount = checked(referenceCount + 1);
			}
		}

		internal void ReleaseReference()
		{
			if (referenceGate == null) return;
			lock (referenceGate)
			{
				if (ReferenceState == ReferenceLifeState.Untracked) return;
				if (referenceCount == 0)
					throw new InvalidOperationException("Releasing an unowned script object.");
				if (--referenceCount != 0 || ReferenceState is ReferenceLifeState.Constructing or ReferenceLifeState.Deleting)
					return;
				referenceState = (int)ReferenceLifeState.Deleting;
			}

			// User code may retain this object or replace the slot which released it.
			HasFinalizer = false;
			try
			{
				if (HasDeleteCall)
					using (Keysharp.Runtime.Flow.EnterUnguarded())
						Keysharp.Runtime.Script.InvokeMeta(this, "__Delete");
			}
			catch { }
			finally
			{
				bool dispose, collectedAgain;
				lock (referenceGate)
				{
					dispose = !referencesEscaped && referenceCount == 0;
					collectedAgain = referencesEscaped && referenceCount == 0;
					referenceState = (int)(dispose ? ReferenceLifeState.Released
						: referencesEscaped ? ReferenceLifeState.Untracked : ReferenceLifeState.Resurrected);
				}
				if (dispose)
				{
					try { ReleaseOwnedReferences(); }
					finally { ReleasePropertyReferences(); }
					try { if (this is IDisposable native) native.Dispose(); }
					catch { }
				}
				else if (collectedAgain)
					ArmAgain();
				else
					MaybeActivateFinalizer();
			}
		}

		private bool PrepareCollectedCleanup()
		{
			if (referenceGate == null) return true;
			lock (referenceGate)
			{
				if (ReferenceState is ReferenceLifeState.Deleting or ReferenceLifeState.Released) return false;
				// Unmigrated scope exits can leave counts after the CLR has proved the object unreachable.
				referenceCount = 0;
				referenceState = (int)ReferenceLifeState.Untracked;
				return true;
			}
		}

		private void ResetReferenceLifetime()
		{
			referenceGate = null;
			referenceState = (int)ReferenceLifeState.Untracked;
			referenceCount = 0;
			referencesEscaped = false;
			ownsProperties = false;
			enumerableProperties = null;
			ResetOwnedReferences();
		}
	}
}
