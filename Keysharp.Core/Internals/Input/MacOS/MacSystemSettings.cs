#if OSX
using Keysharp.Internals.AppleEvents;

namespace Keysharp.Internals.Input.MacOS
{
	internal static partial class MacSystemSettings
	{
		private const string IOKit = "/System/Library/Frameworks/IOKit.framework/IOKit";
		private static readonly nint ParametersKey = CF.CreateString("HIDParameters");
		private static readonly nint ButtonModeKey = CF.CreateString("HIDPointerButtonMode");

		internal static bool MouseButtonsSwapped()
		{
			var service = IOServiceGetMatchingService(0, IOServiceMatching("IOHIDSystem"));

			if (service == 0)
				return false;

			try
			{
				var parameters = IORegistryEntryCreateCFProperty(service, ParametersKey, 0, 0);

				if (parameters == 0)
					return false;

				try
				{
					if (!CF.CFDictionaryGetValueIfPresent(parameters, ButtonModeKey, out var value)
							|| value == 0 || CF.CFGetTypeID(value) != CF.CFNumberGetTypeID()
							|| !CF.CFNumberGetValue(value, 3, out int mode))
						return false;

					// IOHIDButtonModes: 0 maps both buttons to primary, 1 reverses them, 2 enables secondary.
					return mode == 1;
				}
				finally { CF.CFRelease(parameters); }
			}
			finally { _ = IOObjectRelease(service); }
		}

		[LibraryImport(IOKit, StringMarshalling = StringMarshalling.Utf8)]
		private static partial nint IOServiceMatching(string name);

		[LibraryImport(IOKit)]
		private static partial uint IOServiceGetMatchingService(uint mainPort, nint matching);

		[LibraryImport(IOKit)]
		private static partial nint IORegistryEntryCreateCFProperty(uint entry, nint key, nint allocator, uint options);

		[LibraryImport(IOKit)]
		private static partial int IOObjectRelease(uint entry);
	}
}
#endif
