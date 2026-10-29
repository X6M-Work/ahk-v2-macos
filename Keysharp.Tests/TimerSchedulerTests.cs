namespace Keysharp.Tests;

[TestFixture, NonParallelizable, Category("Curated")]
public class TimerSchedulerTests : TestRunner
{
	[Test, Category("Threading")]
	public void BlockedAdmission() => Assert.IsTrue(TestScript("timer-blocked-admission", false));

	[Test, Category("Threading")]
	public void BlockedTimer()
	{
		var output = RunScript(string.Concat(path, "timer-blocked-fires-once.ahk"), "timer-blocked-fires-once", true, false);
		Assert.That(output.Trim(), Is.EqualTo("pass"), output);
	}

	[Test, Category("Threading")]
	public void CallbackSleep() => Assert.IsTrue(TestScript("timer-during-callback-sleep", false));

	[Test, Category("Threading"), Category("Internal")]
	public void LongTimerCoalescing()
	{
		_ = UseQueuedMainContext();
		var scheduler = s.EventScheduler;
		var timers = s.FlowData.timers;
		var calls = 0;
		var callsDuringCallback = 0;
		var maxRunning = 0;
		var startsWithFutureDeadline = true;
		Keysharp.Internals.Threading.ScriptTimerState timer = null;
		timer = timers.Upsert(new KeysharpFunc((Func<object>)(() =>
		{
			calls++;
			maxRunning = System.Math.Max(maxRunning, timer.RunningCount);
			startsWithFutureDeadline &= timer.NextDueTick > Environment.TickCount64;

			if (calls == 1)
			{
				// An expired deadline models an overrun without depending on the host clock's progress.
				timer.NextDueTick = 0;
				scheduler.EnqueueDueTimers();
				scheduler.PumpThreadQueuedEventsCore();
				scheduler.PumpThreadQueuedEventsCore();
				callsDuringCallback = calls;
			}

			return 0L;
		})), scheduler, 60_000L, false, 0L);

		try
		{
			scheduler.PumpThreadQueuedEventsCore();
			Assert.That(calls, Is.Zero);
			timer.NextDueTick = 0;
			scheduler.EnqueueDueTimers();
			scheduler.EnqueueDueTimers();
			scheduler.PumpThreadQueuedEventsCore();
			Assert.That(calls, Is.EqualTo(1), "one queued callback despite repeated due checks");
			Assert.That(callsDuringCallback, Is.EqualTo(1), "an overdue timer cannot reenter its running callback");
			Assert.That(timer.RunningCount, Is.Zero);
			Assert.That(timer.Queued, Is.False);
			Assert.That(timer.NextDueTick, Is.Zero, "completion must preserve the overdue deadline");

			scheduler.PumpThreadQueuedEventsCore();
			Assert.That(calls, Is.EqualTo(2), "an overrun produces one eligible callback after completion");
			scheduler.PumpThreadQueuedEventsCore();
			Assert.That(calls, Is.EqualTo(2), "missed periods must not accumulate a catch-up queue");
			Assert.That(maxRunning, Is.EqualTo(1));
			Assert.That(startsWithFutureDeadline, Is.True, "the next period is measured from callback start");
		}
		finally
		{
			timers.DisableOrDelete(timer);
		}

		Assert.IsTrue(TestScript("timer-long-callback-coalesces", false));
	}

	[TestCase(false), TestCase(true), Category("Threading"), Category("Internal")]
	public void MenuVisible(bool runOnce)
	{
		_ = UseQueuedMainContext();
		var scheduler = s.EventScheduler;
		var timers = s.FlowData.timers;
		var calls = 0;
		var callbackThreadId = 0;
		var timer = timers.Upsert(new KeysharpFunc((Func<object>)(() =>
		{
			calls++;
			callbackThreadId = Environment.CurrentManagedThreadId;
			return 0L;
		})), scheduler, 60_000L, runOnce, 0L);
		s.SetMenuVisible(1, true);

		try
		{
			timer.NextDueTick = 0;
			scheduler.PumpThreadQueuedEventsCore();
			Assert.That(calls, Is.EqualTo(1));
			Assert.That(callbackThreadId, Is.EqualTo(Environment.CurrentManagedThreadId));

			if (!runOnce)
				timer.NextDueTick = 0;

			scheduler.PumpThreadQueuedEventsCore();
			Assert.That(calls, Is.EqualTo(runOnce ? 1 : 2));
			Assert.That(s.IsMenuVisible, Is.True);
		}
		finally
		{
			s.SetMenuVisible(1, false);

			if (timer.IsActive)
				timers.DisableOrDelete(timer);
		}
	}

	[Test, Category("Threading"), Category("Internal")]
	public void NotificationDuringPump()
	{
		var context = UseQueuedMainContext();
		var scheduler = s.EventScheduler;
		_ = scheduler.EnqueueCallback(() =>
		{
			scheduler.WakeForTimerCheck();
			scheduler.WakeForTimerCheck();
		});

		scheduler.PumpThreadQueuedEventsCore();
		// The original post is still in the test transport; the active pass must add one follow-up.
		Assert.That(context.PendingCount, Is.EqualTo(2));
		context.DrainAll();
		Assert.That(context.PendingCount, Is.Zero);
	}

	[Test, Category("Threading")]
	public void ShortTimerPeriod() => Assert.IsTrue(TestScript("timer-short-callback-keeps-period", false));
}
