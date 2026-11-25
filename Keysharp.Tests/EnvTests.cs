namespace Keysharp.Tests;

public class EnvTests : TestRunner
{
	/// <summary>A headless session off Windows may have no clipboard that round-trips at all.</summary>
	private static void RequireClipboard()
	{
#if !WINDOWS
		var clip = Keysharp.Internals.Platform.Clipboard;

		if (clip == null)
			Assert.Ignore("Clipboard is unavailable in this headless environment.");

		clip.SetText("probe");

		if (clip.GetText() != "probe")
			Assert.Ignore("Clipboard text is unavailable in this headless environment.");
#endif
	}

	[Test, Category("Env"), Category("Clipboard"), Category("Desktop"), NonParallelizable]
#if WINDOWS
	[Apartment(ApartmentState.STA)]
#endif
	public void ClipboardAll()
	{
		using var saved = PreserveClipboard();
		RequireClipboard();
		Assert.IsTrue(TestScript("env-clipboardall", true));
	}

	/// <summary>
	/// This can fail periodically, but mostly works.
	/// If it fails in a batch, try running on its own.
	/// </summary>
	[Test, Category("Env"), Category("Clipboard"), Category("Desktop"), NonParallelizable]
#if WINDOWS
	[Apartment(ApartmentState.STA)]
#endif
	public void ClipWait()
	{
		using var saved = PreserveClipboard();
		RequireClipboard();
		Assert.IsTrue(TestScript("env-clipwait", true));
	}

	[Test, Category("Env"), Category("Curated"), NonParallelizable]
	public void EnvGet() => Assert.IsTrue(TestScript("env-envget", true));

	[Test, Category("Env"), Category("Curated"), NonParallelizable]
	public void EnvSet() => Assert.IsTrue(TestScript("env-envset", true));

#if !WINDOWS
	[Test, Category("Env"), NonParallelizable]
	public void EnvSetTracking()
	{
		var key = $"KEYSHARP_ENVUPDATE_{Guid.NewGuid():N}";
		var original = Environment.GetEnvironmentVariable(key);

		try
		{
			_ = Env.EnvSet(key, "first value");
			var firstSnapshot = s.EnvData.SnapshotPendingChanges();
			Assert.AreEqual("first value", firstSnapshot[key]);

			// Simulate EnvSet racing with publication. Acknowledging an older snapshot must
			// not discard the newer value that still needs to be published.
			_ = Env.EnvSet(key, "second value");
			s.EnvData.AcknowledgePublishedChanges(firstSnapshot);
			var secondSnapshot = s.EnvData.SnapshotPendingChanges();
			Assert.AreEqual("second value", secondSnapshot[key]);

			_ = Env.EnvSet(key, null);
			var deletionSnapshot = s.EnvData.SnapshotPendingChanges();
			Assert.IsTrue(deletionSnapshot.ContainsKey(key));
			Assert.IsNull(deletionSnapshot[key]);
		}
		finally
		{
			Environment.SetEnvironmentVariable(key, original);
		}
	}

	[Test, Category("Env"), Category("Internal"), Category("Curated"), NonParallelizable]
	public void EnvUpdateCommands()
	{
		var changes = new Dictionary<string, string>
		{
			["KEYSHARP_ENV_DELETE"] = null,
			["KEYSHARP_ENV_SET"] = "value with spaces"
		};
		var commands = Env.BuildEnvironmentUpdateCommands(changes);

#if LINUX
		Assert.AreEqual(2, commands.Count);
		Assert.AreEqual("dbus-update-activation-environment", commands[0].FileName);
        Assert.That(
            commands[0].Arguments,
            Is.EqualTo(["--systemd", "KEYSHARP_ENV_DELETE=", "KEYSHARP_ENV_SET=value with spaces"]).AsCollection);
		Assert.AreEqual("systemctl", commands[1].FileName);
        Assert.That(
            commands[1].Arguments,
            Is.EqualTo(["--user", "unset-environment", "KEYSHARP_ENV_DELETE"]).AsCollection);
#elif OSX
		Assert.AreEqual(2, commands.Count);
		Assert.AreEqual("/bin/launchctl", commands[0].FileName);
		Assert.That(commands[0].Arguments, Is.EqualTo(new[] { "unsetenv", "KEYSHARP_ENV_DELETE" }).AsCollection);
		Assert.AreEqual("/bin/launchctl", commands[1].FileName);
		Assert.That(commands[1].Arguments, Is.EqualTo(new[] { "setenv", "KEYSHARP_ENV_SET", "value with spaces" }).AsCollection);
#endif
	}
#endif

	[Test, Category("Env"), Category("Curated"), NonParallelizable]
	public void EnvUpdate() => Assert.IsTrue(TestScript("env-envupdate", true));

	[Test, Category("Env"), Category("Curated"), NonParallelizable]
	public void SysGetSafeBootFlagDetection()
	{
		Assert.That(Env.HasBootFlag(null, "-x"), Is.False);
		Assert.That(Env.HasBootFlag("", "-x"), Is.False);
		Assert.That(Env.HasBootFlag("-v debug=0x1", "-x"), Is.False);
		Assert.That(Env.HasBootFlag("-xy", "-x"), Is.False);
		Assert.That(Env.HasBootFlag("-x", "-x"), Is.True);
		Assert.That(Env.HasBootFlag("-v  -x\tdebug=0x1", "-x"), Is.True);
	}

#if OSX
	[Test, Category("Env"), Category("Curated"), NonParallelizable]
	public void MacSysGetVirtualScreenAndDeviceMetrics()
	{
		var monitors = Convert.ToInt64(Env.SysGet((long)Keysharp.Internals.Os.SystemMetric.SM_CMONITORS));
		var primaryW = Convert.ToInt64(Env.SysGet((long)Keysharp.Internals.Os.SystemMetric.SM_CXSCREEN));
		var primaryH = Convert.ToInt64(Env.SysGet((long)Keysharp.Internals.Os.SystemMetric.SM_CYSCREEN));
		var virtX = Convert.ToInt64(Env.SysGet((long)Keysharp.Internals.Os.SystemMetric.SM_XVIRTUALSCREEN));
		var virtY = Convert.ToInt64(Env.SysGet((long)Keysharp.Internals.Os.SystemMetric.SM_YVIRTUALSCREEN));
		var virtW = Convert.ToInt64(Env.SysGet((long)Keysharp.Internals.Os.SystemMetric.SM_CXVIRTUALSCREEN));
		var virtH = Convert.ToInt64(Env.SysGet((long)Keysharp.Internals.Os.SystemMetric.SM_CYVIRTUALSCREEN));

		Assert.That(monitors, Is.GreaterThanOrEqualTo(1L));
		Assert.That(primaryW, Is.GreaterThan(0L));
		Assert.That(primaryH, Is.GreaterThan(0L));
		Assert.That(virtW, Is.GreaterThanOrEqualTo(primaryW));
		Assert.That(virtH, Is.GreaterThanOrEqualTo(primaryH));
		Assert.That(virtX, Is.LessThanOrEqualTo(0L));
		Assert.That(virtY, Is.LessThanOrEqualTo(0L));

		Assert.That(Env.SysGet((long)Keysharp.Internals.Os.SystemMetric.SM_MOUSEPRESENT), Is.EqualTo(1L));
		Assert.That(Env.SysGet((long)Keysharp.Internals.Os.SystemMetric.SM_MOUSEWHEELPRESENT), Is.EqualTo(1L));
		Assert.That(Env.SysGet((long)Keysharp.Internals.Os.SystemMetric.SM_MOUSEHORIZONTALWHEELPRESENT), Is.EqualTo(1L));
		Assert.That(Env.SysGet((long)Keysharp.Internals.Os.SystemMetric.SM_SAMEDISPLAYFORMAT), Is.EqualTo(1L));
		Assert.That(Env.SysGet((long)Keysharp.Internals.Os.SystemMetric.SM_CLEANBOOT), Is.EqualTo(0L));
		Assert.That(Env.SysGet((long)Keysharp.Internals.Os.SystemMetric.SM_SHUTTINGDOWN), Is.EqualTo(0L));
		Assert.That(Env.SysGet((long)Keysharp.Internals.Os.SystemMetric.SM_TABLETPC), Is.EqualTo(0L));
	}
#endif

	[Test, Category("Env"), Category("UI"), NonParallelizable]
#if WINDOWS
	[Category("Curated")]
#endif
	public void SysGet()
	{
		SkipIfUiInitializationBlocked("SysGet relies on Eto screen enumeration, which is unavailable when UI initialization is blocked (macOS testhost cannot drive AppKit).");
		Assert.IsTrue(TestScript("env-sysget", true));
	}
}
