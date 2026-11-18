namespace Keysharp.Builtins
{
	public static class Drive
	{
		/// <summary>
		/// Ejects the tray of the specified CD/DVD drive, or ejects a removable drive.<br/>
		/// Wait for the ejection to finish before continuing.<br/>
		/// Note: This function probably does not work with network drives or non-drive-letter volumes.<br/>
		/// If the tray is already open, DriveEject will still report success.
		/// </summary>
		/// <param name="drive">
		/// If omitted, the default CD/DVD drive will be used.<br/>
		/// Otherwise, specify the drive letter followed by a colon and an optional backslash (might also work on UNC paths and mapped drives).<br/>
		/// Another way to use this function is to specify the unique volume name of the drive (retrievable via mountvol at the command line),
		/// omitting the trailing backslash; for example: "\\?\Volume{26a21bda-a627-11d7-9931-806e6f6e6963}".<br/>
		/// In this case the drive is not required to be assigned a drive letter.
		/// </param>
		/// <exception cref="Error">An <see cref="Error"/> exception is thrown if any failure is detected.</exception>
		public static object DriveEject(object drive = null)
		{
			if (!OptionalDrive(drive, out var text))
				return DefaultObject;

			Platform.Drive.CreateDrive(text).Eject();
			return DefaultObject;
		}

		/// <summary>
		/// Returns the total capacity of the drive which contains the specified path, in megabytes.
		/// </summary>
		/// <param name="path">Any path contained by the drive (might also work on UNC paths and mapped drives).</param>
		/// <returns>The capacity of the drive in megabytes.</returns>
		/// <exception cref="ValueError">A <see cref="ValueError"/> exception is thrown if path is empty.</exception>
		/// <exception cref="OSError">An <see cref="OSError"/> exception is thrown if the drive could not be accessed.</exception>
		public static object DriveGetCapacity(object path)
		{
			if (!path.CoerceString(out var text))
				return DefaultObject;

			return text.Length == 0 ? Errors.InvalidParameterErrorOccurred(1, nameof(DriveGetCapacity), text) : Platform.Drive.CreateDrive(text).Capacity;
		}

		/// <summary>
		/// Returns the type of the specified drive's file system.
		/// </summary>
		/// <param name="drive">The drive letter followed by a colon and an optional backslash, or a UNC name such as "\\server1\share1".</param>
		/// <returns>The type of Drive's file system, where possible values include (but are not limited to) the following:
		/// NTFS, FAT32, FAT, CDFS (typically indicates a CD), or UDF (typically indicates a DVD).<br/>
		/// The return value will be blank if the drive does not contain formatted media.
		/// </returns>
		/// <exception cref="OSError">An <see cref="OSError"/> exception is thrown if the drive could not be accessed.</exception>
		public static object DriveGetFileSystem(object drive)
		{
			if (!drive.CoerceString(out var text))
				return DefaultObject;

			return Platform.Drive.CreateDrive(text).FileSystem;
		}

		/// <summary>
		/// Returns the volume label of the specified drive.
		/// </summary>
		/// <param name="drive">The drive letter followed by a colon and an optional backslash, or a UNC name such as "\server1\share1".</param>
		/// <returns>The drive's volume label.</returns>
		/// <exception cref="OSError">An <see cref="OSError"/> exception is thrown if the drive could not be accessed.</exception>
		public static object DriveGetLabel(object drive)
		{
			if (!drive.CoerceString(out var text))
				return DefaultObject;

			return Platform.Drive.CreateDrive(text).Label;
		}

		/// <summary>
		/// Returns a string of letters, one character for each drive letter in the system.
		/// </summary>
		/// <param name="driveType">If omitted, all drive types are retrieved.<br/>
		/// Otherwise, specify one of the following words, in any case, to retrieve only a specific type of drive: CDROM, REMOVABLE, FIXED, NETWORK, RAMDISK, UNKNOWN.
		/// </param>
		/// <returns>The drive letters in the system, depending on DriveType. For example: ACDEZ.</returns>
		/// <exception cref="ValueError">A <see cref="ValueError"/> exception is thrown if driveType is not one of those words.</exception>
		public static string DriveGetList(object driveType = null)
		{
			DriveType? type = null;

			// As in AutoHotkey, only an omitted type lists every drive; an empty or unknown word is an error.
			if (driveType != null)
			{
				if (!driveType.CoerceString(out var drivetype))
					return "";

				type = Script.TheScript.DriveTypeMapper.LookUpCLRType(drivetype);

				if (!type.HasValue)
					return (string)Errors.ValueErrorOccurred($"Unknown drive type \"{drivetype}\". Expected CDROM, REMOVABLE, FIXED, NETWORK, RAMDISK or UNKNOWN.", drivetype, DefaultErrorString);
			}

			var drives = DriveInfo.GetDrives();
#if !WINDOWS
			var list = new List<string>(drives.Length);

			for (var i = 0; i < drives.Length; i++)
			{
				try
				{
					if (type.HasValue)
					{
						if (drives[i].DriveType == type.Value)
							list.Add(drives[i].Name);
					}
					else
					{
						if (drives[i].DriveType != DriveType.Unknown)
							list.Add(drives[i].Name);
					}
				}
				catch
				{
					// Ignore inaccessible/virtual mounts while enumerating.
				}
			}

			return string.Join(";", list);
#else
			var str = "";

			for (var i = 0; i < drives.Length; i++)
			{
				if (type.HasValue)
				{
					if (drives[i].DriveType == type.Value)
						str += drives[i].Name[0];
				}
				else
					str += drives[i].Name[0];
			}

			return str;
#endif
		}

		/// <summary>
		/// Returns the volume serial number of the specified drive.
		/// </summary>
		/// <param name="drive">The drive letter followed by a colon and an optional backslash, or a UNC name such as "\server1\share1".</param>
		/// <returns>The drive's volume serial number. On Linux and macOS it is taken from the file system's UUID.</returns>
		/// <exception cref="OSError">An <see cref="OSError"/> exception is thrown if the drive could not be accessed, or on Linux
		/// and macOS if its file system has no UUID.</exception>
		public static object DriveGetSerial(object drive)
		{
			if (!drive.CoerceString(out var text))
				return DefaultObject;

			return Platform.Drive.CreateDrive(text).Serial;
		}

		/// <summary>
		/// Returns the free disk space of the drive which contains the specified path, in megabytes.
		/// </summary>
		/// <param name="path">Any path contained by the drive (might also work on UNC paths and mapped drives).</param>
		/// <returns>The free disk space of the drive which contains Path, in megabytes (rounded down to the nearest megabyte).</returns>
		/// <exception cref="ValueError">A <see cref="ValueError"/> exception is thrown if path is empty.</exception>
		/// <exception cref="OSError">An <see cref="OSError"/> exception is thrown if the drive could not be accessed.</exception>
		public static object DriveGetSpaceFree(object path)
		{
			if (!path.CoerceString(out var text))
				return DefaultObject;

			return text.Length == 0 ? Errors.InvalidParameterErrorOccurred(1, nameof(DriveGetSpaceFree), text) : Platform.Drive.CreateDrive(text).SpaceFree;
		}

		/// <summary>
		/// Returns the status of the drive which contains the specified path.
		/// </summary>
		/// <param name="path">Any path contained by the drive (might also work on UNC paths and mapped drives).</param>
		/// <returns>The status of the drive:<br/>
		/// Unknown: Might indicate unformatted/RAW file system.<br/>
		/// Ready: This is the most common.<br/>
		/// NotReady: Typical for removable drives that don't contain media.<br/>
		/// ReadOnly: The drive is write-protected.<br/>
		/// Invalid: Path does not exist or is a network drive that is presently inaccessible, etc.
		/// </returns>
		public static string DriveGetStatus(object path)
		{
			if (!path.CoerceString(out var text))
				return "";

			return Platform.Drive.CreateDrive(text).Status;
		}

		/// <summary>
		/// Returns the media status of the specified CD/DVD drive.
		/// </summary>
		/// <param name="drive">If omitted, the default CD/DVD drive will be used. Otherwise, specify the drive letter optionally followed by a colon or a colon and backslash.</param>
		/// <returns>The drive's media status:<br/>
		/// not ready: The drive is not ready to be accessed, perhaps due to being engaged in a write operation. Known limitation: "not ready" also occurs when the drive contains a DVD rather than a CD.<br/>
		/// open: The drive contains no disc, or the tray is ejected.<br/>
		/// playing: The drive is playing a disc.<br/>
		/// paused: The previously playing audio or video is now paused.<br/>
		/// seeking: The drive is seeking.<br/>
		/// stopped: The drive contains a CD but is currently not accessing it.<br/>
		/// This function will probably not work on a network drive or non-drive-letter volume. If it fails in such cases or for any other reason, an exception is thrown.
		/// </returns>
		/// <exception cref="Error">An <see cref="Error"/> exception is thrown if any failure is detected.</exception>
		public static string DriveGetStatusCD(object drive = null)
		{
			if (!OptionalDrive(drive, out var text))
				return "";

			return Platform.Drive.CreateDrive(text).StatusCD;
		}

		/// <summary>
		/// Returns the type of the drive which contains the specified path.
		/// </summary>
		/// <param name="path">Any path contained by the drive (might also work on UNC paths and mapped drives).</param>
		/// <returns>The type of Drive, which is one of the following words: Unknown, Removable, Fixed, Network, CDROM, RAMDisk,
		/// or an empty string if Path is invalid (for example, because the drive does not exist).</returns>
		public static string DriveGetType(object path)
		{
			if (!path.CoerceString(out var text))
				return "";

			return Platform.Drive.CreateDrive(text).Type;
		}

		/// <summary>
		/// Prevents the eject feature of the specified drive from working.
		/// </summary>
		/// <param name="drive">The drive letter optionally followed by a colon or a colon and backslash.</param>
		/// <exception cref="ValueError">On Windows, a <see cref="ValueError"/> exception is thrown if drive is not a drive letter.</exception>
		/// <exception cref="OSError">An <see cref="OSError"/> exception is thrown if the drive could not be locked.</exception>
		/// <exception cref="UnsupportedError">An <see cref="UnsupportedError"/> exception is thrown on macOS.</exception>
		public static object DriveLock(object drive)
		{
			if (!drive.CoerceString(out var text))
				return DefaultObject;

			Platform.Drive.CreateDrive(text).Lock();
			return DefaultObject;
		}

		/// <summary>
		/// Retracts (closes) the tray of the specified CD/DVD drive.<br/>
		/// Wait for the retraction to finish before continuing.<br/>
		/// If the tray is already closed, DriveRetract will still report success.<br/>
		/// Note: This function probably does not work with network drives or non-drive-letter volumes.
		/// </summary>
		/// <param name="drive">
		/// If omitted, the default CD/DVD drive will be used.<br/>
		/// Otherwise, specify the drive letter followed by a colon and an optional backslash (might also work on UNC paths and mapped drives).<br/>
		/// Another way to use this function is to specify the unique volume name of the drive (retrievable via mountvol at the command line),
		/// omitting the trailing backslash; for example: "\\?\Volume{26a21bda-a627-11d7-9931-806e6f6e6963}".<br/>
		/// In this case the drive is not required to be assigned a drive letter.
		/// </param>
		/// <exception cref="Error">An <see cref="Error"/> exception is thrown if any failure is detected.</exception>
		public static object DriveRetract(object drive = null)
		{
			if (!OptionalDrive(drive, out var text))
				return DefaultObject;

			Platform.Drive.CreateDrive(text).Retract();
			return DefaultObject;
		}

		/// <summary>
		/// Changes the volume label of the specified drive.<br/>
		/// The operation may require administrator/root privileges.
		/// </summary>
		/// <param name="drive">The drive letter followed by a colon and an optional backslash, or a UNC name such as "\\server1\share1".</param>
		/// <param name="newLabel">If omitted, the drive will have no label. Otherwise, specify the new label.</param>
		/// <exception cref="OSError">An <see cref="OSError"/> exception is thrown if the label could not be changed.</exception>
		public static object DriveSetLabel(object drive, object newLabel = null)
		{
			if (!drive.CoerceString(out var driveName) || !newLabel.CoerceString(out var label))
				return DefaultObject;

			Platform.Drive.CreateDrive(driveName).SetLabel(label);
			return DefaultObject;
		}

		/// <summary>
		/// Restores the eject feature of the specified drive.
		/// </summary>
		/// <param name="drive">The drive letter optionally followed by a colon or a colon and backslash.</param>
		/// <exception cref="ValueError">On Windows, a <see cref="ValueError"/> exception is thrown if drive is not a drive letter.</exception>
		/// <exception cref="OSError">An <see cref="OSError"/> exception is thrown if the drive could not be unlocked.</exception>
		/// <exception cref="UnsupportedError">An <see cref="UnsupportedError"/> exception is thrown on macOS.</exception>
		public static object DriveUnlock(object drive)
		{
			if (!drive.CoerceString(out var text))
				return DefaultObject;

			Platform.Drive.CreateDrive(text).UnLock();
			return DefaultObject;
		}

		// An omitted drive stays null, which selects the default CD/DVD drive; an empty string is a drive that does not exist.
		private static bool OptionalDrive(object drive, out string text)
		{
			text = null;
			return drive == null || drive.CoerceString(out text);
		}

		internal static long ParseMacVolumeSerialFromDiskutilInfo(string output)
		{
			if (string.IsNullOrWhiteSpace(output))
				return 0L;

			foreach (var rawLine in output.Split(['\r', '\n'], StringSplitOptions.RemoveEmptyEntries))
			{
				var colon = rawLine.IndexOf(':');
				if (colon <= 0)
					continue;

				var key = rawLine[..colon].Trim();
				if (!string.Equals(key, "Volume UUID", StringComparison.OrdinalIgnoreCase))
					continue;

				var uuid = rawLine[(colon + 1)..].Trim().Replace("-", "");
				if (uuid.Length >= 8 && long.TryParse(
					uuid.AsSpan(0, 8),
					System.Globalization.NumberStyles.HexNumber,
					System.Globalization.CultureInfo.InvariantCulture,
					out var serial))
					return serial;
			}

			return 0L;
		}
	}
}
