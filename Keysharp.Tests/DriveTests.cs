namespace Keysharp.Tests;

public class DriveTests : TestRunner
{
	[Test, Category("Drive"), Category("Curated")]
	public void DriveGetSpaceFree() => Assert.IsTrue(TestScript("drive-getspacefree", true));

	[Test, Category("Drive"), Category("Curated")]
	public void DriveGetCapacity() => Assert.IsTrue(TestScript("drive-getcapacity", true));

	[Test, Category("Drive"), Category("Curated")]
	public void DriveGetFileSystem() => Assert.IsTrue(TestScript("drive-getfilesystem", true));

	[Test, Category("Drive"), Category("Curated")]
	public void DriveGetList() => Assert.IsTrue(TestScript("drive-getlist", true));

	[Test, Category("Drive"), Category("Curated")]
	public void DriveGetSerial() => Assert.IsTrue(TestScript("drive-getserial", true));

	[Test, Category("Drive"), Category("Curated")]
	public void DriveGetType() => Assert.IsTrue(TestScript("drive-gettype", true));

	[Test, Category("Drive"), Category("Curated")]
	public void DriveGetStatus() => Assert.IsTrue(TestScript("drive-getstatus", true));

#if WINDOWS

	[Test, Category("Drive"), Category("DisposableVolume")]
	public void DriveGetSetLabel()
	{
		RequireDisposableTestVolume();
		if (!Accessors.A_IsAdmin)
			Assert.Ignore("DriveSetLabel requires administrator rights.");

		Assert.IsTrue(TestScript("drive-getsetlabel", true));
	}

#endif
}
