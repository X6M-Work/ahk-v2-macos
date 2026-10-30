namespace Keysharp.Tests;

[TestFixture, NonParallelizable, Category("Internal"), Category("Curated")]
public class ReferenceLifetimeTests : TestRunner
{
	[ReferenceCounted]
	private sealed class Probe : KeysharpObject, IDisposable
	{
		internal int Deletes, Disposes;
		internal Action Deleting;

		internal Probe() : base(null)
		{
			DefinePropInternal("__Delete", new OwnPropsDesc { Call = Functions.Func((Func<object, object>)__Delete) });
			BeginReferenceConstruction();
			CompleteReferenceConstruction();
		}

		public override object __Delete()
		{
			Deletes++;
			Deleting?.Invoke();
			return 0L;
		}

		public static object __Delete(object receiver) => ((Probe)receiver).__Delete();
		internal override bool HasDeleteCall => true;

		public void Dispose() => Disposes++;
		internal Probe Copy() => (Probe)MemberwiseClone();
	}

	[Test]
	public void UninstrumentedInstancesKeepTheirExistingLifetime()
	{
		foreach (Any value in new Any[] { new Any(null), new Ks.HashMap(null), new LegacyMap(), new LegacyArray(), new MarkedLegacyMap(), new MarkedHashMap() })
		{
			value.BeginReferenceConstruction();
			value.CompleteReferenceConstruction();
			Lifetime.Retain(value);
			Lifetime.Release(value);
			Assert.That(value.ReferenceState, Is.EqualTo(ReferenceLifeState.Untracked));
		}
	}

	private class LegacyMap() : Keysharp.Builtins.Map(null);
	private sealed class LegacyArray() : Keysharp.Builtins.Array(null);
	[ReferenceCounted]
	private sealed class MarkedLegacyMap() : LegacyMap;
	[ReferenceCounted]
	private sealed class MarkedHashMap() : Ks.HashMap(null);

	[Test]
	public void MapDictionaryMutationsBalanceOwnedEdges()
	{
		var map = new Keysharp.Builtins.Map(null);
		map.BeginReferenceConstruction();
		map.CompleteReferenceConstruction();
		Lifetime.Retain(map);
		IDictionary<object, object> dictionary = map;
		var key = new Probe();
		var original = new Probe();
		var replacement = new Probe();
		dictionary.Add(key, original);
		dictionary[key] = original;
		Assert.That((key.Deletes, original.Deletes), Is.EqualTo((0, 0)));
		dictionary[key] = replacement;
		Assert.That(original.Deletes, Is.EqualTo(1));
		Assert.That(dictionary.Remove(key), Is.True);
		Assert.That((key.Deletes, replacement.Deletes), Is.EqualTo((1, 1)));
		ICollection<KeyValuePair<object, object>> pairs = map;
		var last = new Probe();
		pairs.Add(new("last", last));
		Assert.That(pairs.Remove(new("last", null)), Is.False);
		Assert.That(last.Deletes, Is.Zero);
		Assert.That(pairs.Remove(new("last", last)), Is.True);
		Assert.That(last.Deletes, Is.EqualTo(1));
		dictionary.Add(1, null);
		dictionary.Add(1L, null);
		Assert.That(map.Count, Is.EqualTo(2));
		Assert.That(dictionary.Remove(1), Is.True);
		Assert.That(dictionary.ContainsKey(1L), Is.True);
		Lifetime.Release(map);
	}

	[Test]
	public void MapClrReadTransfersValuesToCollectedOwnership()
	{
		var map = new Keysharp.Builtins.Map(null);
		map.BeginReferenceConstruction();
		map.CompleteReferenceConstruction();
		Lifetime.Retain(map);
		IDictionary<object, object> dictionary = map;
		var value = new Probe();
		dictionary.Add("key", value);
		Assert.That(dictionary["key"], Is.SameAs(value));
		Assert.That(value.ReferenceState, Is.EqualTo(ReferenceLifeState.Untracked));
		Lifetime.Release(map);
		Assert.That(value.Deletes, Is.Zero);
		GC.KeepAlive(value);
	}

	[Test]
	public void ResurrectionDefersNativeDisposal()
	{
		var probe = new Probe();
		probe.Deleting = () => { if (probe.Deletes == 1) Lifetime.Retain(probe); };
		object slot = null;
		Lifetime.Replace(ref slot, probe);
		Lifetime.Replace(ref slot, null);
		Assert.That(probe.ReferenceState, Is.EqualTo(ReferenceLifeState.Resurrected));
		Assert.That((probe.Deletes, probe.Disposes), Is.EqualTo((1, 0)));
		Assert.That(Lifetime.Borrow(probe), Is.SameAs(probe));
		Assert.That(probe.ReferenceState, Is.EqualTo(ReferenceLifeState.Resurrected));
		Assert.That((probe.Deletes, probe.Disposes), Is.EqualTo((1, 0)));
		Lifetime.Release(probe);
		Assert.That(probe.ReferenceState, Is.EqualTo(ReferenceLifeState.Released));
		Assert.That((probe.Deletes, probe.Disposes), Is.EqualTo((2, 1)));
		Assert.Throws<InvalidOperationException>(() => Lifetime.Retain(probe));
	}

	[Test]
	public void DeleteReentryDoesNotHoldTheCounterLock()
	{
		var probe = new Probe();
		var completed = false;
		System.Threading.Tasks.Task worker = null;
		probe.Deleting = () =>
		{
			worker = System.Threading.Tasks.Task.Run(() => { Lifetime.Retain(probe); Lifetime.Release(probe); });
			completed = worker.Wait(TimeSpan.FromSeconds(10));
		};
		Lifetime.Retain(probe);
		Lifetime.Release(probe);
		Assert.That(completed, Is.True, "__Delete ran while another thread could not retain/release its receiver");
		Assert.That((probe.Deletes, probe.Disposes), Is.EqualTo((1, 1)));
		worker?.GetAwaiter().GetResult();
	}

	[Test]
	public void DeleteFailureStillCompletesCleanup()
	{
		var probe = new Probe { Deleting = () => throw new InvalidOperationException("delete failure") };
		Lifetime.Retain(probe);
		Lifetime.Release(probe);
		Assert.That(probe.ReferenceState, Is.EqualTo(ReferenceLifeState.Released));
		Assert.That((probe.Deletes, probe.Disposes), Is.EqualTo((1, 1)));
	}

	[Test]
	public void QueuedCleanupCannotDeleteAReleasedObjectTwice()
	{
		var probe = new Probe();
		Lifetime.Retain(probe);
		Lifetime.Release(probe);
		s.DestructorPump.Enqueue(probe);
		s.DestructorPump.RunPendingDestructors();
		Assert.That((probe.Deletes, probe.Disposes), Is.EqualTo((1, 1)));
	}

	[Test]
	public void CloneHasIndependentLifetimeState()
	{
		var original = new Probe();
		Lifetime.Retain(original);
		var clone = original.Copy();
		Assert.That(clone.ReferenceState, Is.EqualTo(ReferenceLifeState.Untracked));
		Lifetime.Release(original);
		Assert.That((original.Deletes, original.Disposes), Is.EqualTo((1, 1)));
		Assert.That((clone.Deletes, clone.Disposes), Is.EqualTo((0, 0)));
		GC.KeepAlive(clone);
	}

	[Test]
	public void ScopedBoxReleasesStoredValueWhenLastBoxReferenceDrops()
	{
		var probe = new Probe();
		var box = Lifetime.Box(probe);
		object exported = null;
		Lifetime.Replace(ref exported, box);
		Lifetime.ReleaseScope(box);
		Assert.That((probe.Deletes, probe.Disposes), Is.EqualTo((0, 0)));
		Lifetime.Replace(ref exported, null);
		Assert.That((probe.Deletes, probe.Disposes), Is.EqualTo((1, 1)));
	}

	[Test]
	public void ReleaseScopeSkipsDestructorsAfterScriptExit()
	{
		var probe = new Probe();
		Lifetime.Retain(probe);
		var previousExited = s.hasExited;
		try
		{
			s.hasExited = true;
			Lifetime.ReleaseScope(probe);
			Assert.That((probe.Deletes, probe.Disposes), Is.EqualTo((0, 0)));
		}
		finally
		{
			s.hasExited = previousExited;
			Lifetime.Release(probe);
		}
		Assert.That((probe.Deletes, probe.Disposes), Is.EqualTo((1, 1)));
	}
}
