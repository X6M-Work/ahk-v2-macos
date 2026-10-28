namespace Keysharp.Tests;

[Category("Internal"), Category("Curated")]
public class AppHostTemplateInternalsTests
{
	[TestCase("sdk"), TestCase("pack")]
	public void FindsNewestMatchingMajorWithExistingTemplate(string kind)
	{
		WithTemporaryRoot(root =>
		{
			_ = Template(root, kind, "10.0.99");
			_ = Template(root, kind, "10.0.100-rc.1");
			var expected = Template(root, kind, "10.0.100");
			_ = Template(root, kind, "100.0.100");
			_ = Template(root, kind, "10.bad");
			Directory.CreateDirectory(Path.GetDirectoryName(TemplatePath(root, kind, "10.0.999")));
			Assert.That(Keysharp.Main.AppHostTemplate.FindAppHostTemplate([root]), Is.EqualTo(expected));
		});
	}

	[Test]
	public void FallsBackToNextInstallationWithMatchingHost()
	{
		WithTemporaryRoot(root =>
		{
			var first = Path.Combine(root, "first");
			var second = Path.Combine(root, "second");
			_ = Template(first, "sdk", "9.0.100");
			var expected = Template(second, "pack", "10.0.13");
			Assert.That(Keysharp.Main.AppHostTemplate.FindAppHostTemplate([first, second]), Is.EqualTo(expected));
			Assert.That(Keysharp.Main.AppHostTemplate.FindAppHostTemplate([first]), Is.Null);
		});
	}

	private static string Template(string root, string kind, string version)
	{
		var path = TemplatePath(root, kind, version);
		Directory.CreateDirectory(Path.GetDirectoryName(path));
		File.WriteAllText(path, "host");
		return path;
	}

	private static string TemplatePath(string root, string kind, string version)
	{
		var name = OperatingSystem.IsWindows() ? "apphost.exe" : "apphost";
		if (kind == "sdk")
			return Path.Combine(root, "sdk", version, "AppHostTemplate", name);
		var arch = RuntimeInformation.ProcessArchitecture == Architecture.Arm64 ? "arm64" : "x64";
		var rid = $"{(OperatingSystem.IsWindows() ? "win" : OperatingSystem.IsMacOS() ? "osx" : "linux")}-{arch}";
		return Path.Combine(root, "packs", $"Microsoft.NETCore.App.Host.{rid}", version, "runtimes", rid, "native", name);
	}

	private static void WithTemporaryRoot(Action<string> action)
	{
		var parent = Path.GetFullPath(Path.GetTempPath());
		var root = Path.GetFullPath(Path.Combine(parent, "ks-apphost-" + Guid.NewGuid().ToString("N")));
		Assert.That(Path.GetDirectoryName(root), Is.EqualTo(parent.TrimEnd(Path.DirectorySeparatorChar)));
		Directory.CreateDirectory(root);
		try { action(root); }
		finally { Directory.Delete(root, true); }
	}
}
