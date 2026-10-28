namespace Keysharp.Main;

internal static class AppHostTemplate
{
	internal static string FindAppHostTemplate()
	{
		var roots = new List<string>();
		void AddRoot(string root)
		{
			if (!string.IsNullOrEmpty(root) && Directory.Exists(root))
				roots.Add(Path.GetFullPath(root));
		}
		try
		{
			AddRoot(Path.Combine(RuntimeEnvironment.GetRuntimeDirectory(), "..", "..", ".."));
		}
		catch { }
		AddRoot(Environment.GetEnvironmentVariable($"DOTNET_ROOT_{RuntimeInformation.ProcessArchitecture.ToString().ToUpperInvariant()}"));
		AddRoot(Environment.GetEnvironmentVariable("DOTNET_ROOT"));
#if WINDOWS
		AddRoot(Path.Combine(Environment.GetFolderPath(Environment.SpecialFolder.ProgramFiles), "dotnet"));
		AddRoot(Path.Combine(Environment.GetFolderPath(Environment.SpecialFolder.UserProfile), ".dotnet"));
#elif LINUX
		AddRoot("/usr/share/dotnet");
		AddRoot("/usr/lib/dotnet");
		AddRoot("/lib/dotnet");
#else
		AddRoot("/usr/local/share/dotnet");
		AddRoot("/usr/share/dotnet");
		AddRoot(Path.Combine(Environment.GetFolderPath(Environment.SpecialFolder.UserProfile), ".dotnet"));
#endif
		return FindAppHostTemplate(roots.Distinct());
	}

	internal static string FindAppHostTemplate(IEnumerable<string> roots)
	{
		var arch = RuntimeInformation.ProcessArchitecture == Architecture.Arm64 ? "arm64" : "x64";
		var rid = $"{(OperatingSystem.IsWindows() ? "win" : OperatingSystem.IsMacOS() ? "osx" : "linux")}-{arch}";
		var hostName = OperatingSystem.IsWindows() ? "apphost.exe" : "apphost";
		foreach (var root in roots)
		{
			if (NewestHost(Path.Combine(root, "sdk"), Path.Combine("AppHostTemplate", hostName)) is { } sdkHost)
				return sdkHost;
			if (NewestHost(Path.Combine(root, "packs", $"Microsoft.NETCore.App.Host.{rid}"), Path.Combine("runtimes", rid, "native", hostName)) is { } packHost)
				return packHost;
		}
		return null;
	}

	private static string NewestHost(string versionsDir, string relativePath) => !Directory.Exists(versionsDir) ? null
		: Directory.GetDirectories(versionsDir)
		.Where(dir => ParseVersion(Path.GetFileName(dir)).Major.ToString() == Script.dotNetMajorVersion)
		.OrderByDescending(dir => ParseVersion(Path.GetFileName(dir)))
		.ThenBy(dir => Path.GetFileName(dir).Contains('-'))
		.Select(dir => Path.Combine(dir, relativePath))
		.FirstOrDefault(File.Exists);

	private static Version ParseVersion(string name)
	{
		var dash = name.IndexOf('-');
		return Version.TryParse(dash < 0 ? name : name[..dash], out var version) ? version : new Version(0, 0);
	}
}
