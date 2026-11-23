namespace Keysharp.Tests;

public partial class ProcessTests : TestRunner
{
	[Test, Category("Process"), Category("Curated")]
	public void ProcessRunWaitClose() => Assert.IsTrue(TestScript("process-run-wait-close", false));

	[Test, Category("Internal"), Category("Curated")]
	public void ProcessExistAfterExit()
	{
		var start = new ProcessStartInfo
		{
#if WINDOWS
			FileName = Environment.GetEnvironmentVariable("ComSpec") ?? "cmd.exe",
#else
			FileName = "/bin/sh",
#endif
			UseShellExecute = false,
			CreateNoWindow = true
		};
#if WINDOWS
		start.ArgumentList.Add("/c");
#else
		start.ArgumentList.Add("-c");
#endif
		start.ArgumentList.Add("exit 0");
		using var child = Process.Start(start);
		Assert.That(child, Is.Not.Null);
		Assert.IsTrue(child.WaitForExit(5000));
		var threadId = Environment.CurrentManagedThreadId;
		var exceptions = new List<Exception>();
		long currentPid, exitedPid;

		void RecordException(object sender, FirstChanceExceptionEventArgs args)
		{
			if (Environment.CurrentManagedThreadId == threadId && args.Exception is ArgumentException)
				exceptions.Add(args.Exception);
		}

		AppDomain.CurrentDomain.FirstChanceException += RecordException;
		try
		{
			currentPid = Processes.ProcessExist(Environment.ProcessId);
			exitedPid = Processes.ProcessExist(child.Id);
		}
		finally
		{
			AppDomain.CurrentDomain.FirstChanceException -= RecordException;
		}

		Assert.That(currentPid, Is.EqualTo(Environment.ProcessId));
		Assert.That(exitedPid, Is.Zero);
		Assert.IsEmpty(exceptions, "An exited PID must be an ordinary lookup miss, without a first-chance ArgumentException.");
	}

	[Test, Category("Process"), Category("Curated")]
	public void ProcessGetParent() => Assert.IsTrue(TestScript("process-get-parent", false));

	[Test, Category("Process"), Category("Curated")]
	public void ProcessRunScript() => Assert.IsTrue(TestScript("process-runscript", false));

	[Test, Category("Process"), Category("Curated")]
	public void ProcessGetPathAndNameResolveCurrentProcess()
	{
		var resolvedPath = Processes.ProcessGetPath(Environment.ProcessId);
		var resolvedName = Processes.ProcessGetName(Environment.ProcessId);
		Assert.That(resolvedPath, Is.Not.Null.And.Not.Empty);
		Assert.That(File.Exists(resolvedPath), Is.True);
		Assert.That(resolvedName, Is.EqualTo(Path.GetFileName(resolvedPath)));
		if (!string.IsNullOrEmpty(Environment.ProcessPath))
			Assert.That(resolvedName, Is.EqualTo(Path.GetFileName(Environment.ProcessPath)).IgnoreCase);

#if OSX
		Assert.That(Keysharp.Internals.Platform.Process.TryGetExecutablePath(Environment.ProcessId, out var pidPath), Is.True);
		Assert.That(pidPath, Is.Not.Empty);
		Assert.That(Processes.ProcessGetPath(1), Is.TypeOf<string>());
#endif
	}

	[Test, Category("Process"), Category("Internal"), Category("Curated")]
	public void ProcessSetPriorityReturnsZeroOnUnpermittedOrExitedProcess()
	{
		Assert.That(Processes.ProcessSetPriority("H", -1L), Is.Zero);
		Assert.That(Processes.TryApplyProcessPriority(null, ProcessPriorityClass.Normal), Is.Zero);

		var exitedStart = new ProcessStartInfo
		{
#if WINDOWS
			FileName = Environment.GetEnvironmentVariable("ComSpec") ?? "cmd.exe",
#else
			FileName = "/bin/sh",
#endif
			UseShellExecute = false,
			CreateNoWindow = true
		};
#if WINDOWS
		exitedStart.ArgumentList.Add("/c");
#else
		exitedStart.ArgumentList.Add("-c");
#endif
		exitedStart.ArgumentList.Add("exit 0");
		using (var exited = Process.Start(exitedStart))
		{
			Assert.That(exited, Is.Not.Null);
			Assert.IsTrue(exited.WaitForExit(5000));
			Assert.That(Processes.TryApplyProcessPriority(exited, ProcessPriorityClass.Normal), Is.Zero);
		}

		var liveStart = new ProcessStartInfo
		{
#if WINDOWS
			FileName = Environment.GetEnvironmentVariable("ComSpec") ?? "cmd.exe",
#else
			FileName = "/bin/sleep",
#endif
			UseShellExecute = false,
			CreateNoWindow = true
		};
#if WINDOWS
		liveStart.ArgumentList.Add("/c");
		liveStart.ArgumentList.Add("ping -n 6 127.0.0.1 >nul");
#else
		liveStart.ArgumentList.Add("5");
#endif
		using var live = Process.Start(liveStart);
		Assert.That(live, Is.Not.Null);

		try
		{
			var normal = Processes.ProcessSetPriority("Normal,High", (long)live.Id);
			Assert.That(normal, Is.EqualTo(live.Id));
			var lowered = Processes.ProcessSetPriority("Below", (long)live.Id);
			Assert.That(lowered, Is.EqualTo(live.Id));
			var raised = Processes.ProcessSetPriority("H", (long)live.Id);
			Assert.That(raised == 0L || raised == live.Id, Is.True);
		}
		finally
		{
			try
			{
				if (!live.HasExited)
					live.Kill(true);
			}
			catch
			{
			}
		}
	}
}
