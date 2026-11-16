using Keysharp.Builtins;
#if OSX

namespace Keysharp.Internals.Mapper.MacOS
{
	/// <summary>
	/// Concrete implementation of Drive for the macOS platform.
	/// </summary>
	internal class Drive : DriveBase
	{
		internal override long Serial
		{
			get
			{
				var result = RunCommand("/usr/sbin/diskutil", ["info", drive.Name]);
				return result.Succeeded ? Keysharp.Builtins.Drive.ParseMacVolumeSerialFromDiskutilInfo(result.StandardOutput) : 0L;
			}
		}

		internal override string StatusCD
		{
			get
			{
				Diagnostics.Debug.WriteLine($"Obtaining the status of the CD/DVD drive is not supported on macOS.");
				return DefaultObject;
			}
		}

		internal Drive(DriveInfo drv)
			: base(drv) { }

		internal override void Eject()
		{
			var result = RunCommand("/usr/sbin/diskutil", ["eject", drive.Name]);
			if (!result.Succeeded)
				Diagnostics.Debug.WriteLine($"Drive.Eject failed for {drive.Name}: {result.ErrorMessage}");
		}

		internal override void Lock()
		{
			Diagnostics.Debug.WriteLine($"Locking the eject ability of a drive is not supported on macOS.");
		}

		internal override void Retract()
		{
			var result = RunCommand("/usr/bin/drutil", ["tray", "close"]);
			if (!result.Succeeded)
				Diagnostics.Debug.WriteLine($"Drive.Retract failed for {drive.Name}: {result.ErrorMessage}");
		}

		internal override void SetLabel(string label)
		{
			var result = RunCommand("/usr/sbin/diskutil", ["renameVolume", drive.Name, label]);

			if (!result.Succeeded)
				throw new IOException(result.ErrorMessage);
		}

		internal override void UnLock()
		{
			Diagnostics.Debug.WriteLine($"Unlocking the eject ability of a drive is not supported on macOS.");
		}
	}
}
#endif
