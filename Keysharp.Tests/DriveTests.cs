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

	[Test, Category("Drive"), Category("Internal"), Category("Curated")]
	public void ParseMacVolumeSerialFromDiskutilInfoExtractsUuidHex()
	{
		const string sample = """
			   Device Identifier:         disk3s1s1
			   Volume Name:               Macintosh HD
			   Volume UUID:               1A2B3C4D-5E6F-7080-90A0-B0C0D0E0F001
			   Disk Size:                 494.38 GB
			""";
		Assert.That(Drive.ParseMacVolumeSerialFromDiskutilInfo(sample), Is.EqualTo(0x1A2B3C4DL));
		Assert.That(Drive.ParseMacVolumeSerialFromDiskutilInfo("Device Name: disk0"), Is.EqualTo(0L));
		Assert.That(Drive.ParseMacVolumeSerialFromDiskutilInfo(null), Is.EqualTo(0L));
	}

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
