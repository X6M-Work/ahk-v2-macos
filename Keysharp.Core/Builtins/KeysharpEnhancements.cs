namespace Keysharp.Builtins
{
	/// <summary>
	/// A class to put functions which are new to Keysharp that serve as an
	/// improvement/addition to AHK.
	/// </summary>
	public partial class Ks
	{
		/// <summary>
		/// Calls GC.Collect().
		/// According to .NET design guidelines, this should never be necessary.
		/// </summary>
		public static object Collect()
		{
			GC.Collect();
			return DefaultObject;
		}

		/// <summary>
		/// Shows the debug tab in the main window.
		/// Using this anywhere in the script will also make it persistent.
		/// </summary>
		public static object ShowDebug()
		{
			Script.TheScript.mainWindow?.ShowDebug();
			return DefaultObject;
		}

		/// <summary>
		/// Sends a string followed by a newline to the debugger (if any) for display.
		/// </summary>
		/// <param name="text">The text to send to the debugger for display.</param>
		/// <param name="clear">True to first clear the display, else false to append.</param>
		public static object OutputDebugLine(object text, object clear = null) => Diagnostics.Debug.WriteLine(text, clear);

		/// <summary>
		/// Executes an inline AppleScript via <c>/usr/bin/osascript</c> on macOS and returns its standard output.
		/// Additional parameters are forwarded as command-line arguments to the script's <c>on run argv</c> handler.
		/// </summary>
		/// <param name="script">The AppleScript source code to execute.</param>
		/// <param name="args">Optional arguments passed to the script.</param>
		/// <returns>The trimmed standard output produced by <c>osascript</c>.</returns>
		public static object AppleScript(object script, params object[] args) => RunOsascriptBuiltIn(script, null, args);

		/// <summary>
		/// Executes inline JavaScript for Automation (JXA) via <c>/usr/bin/osascript -l JavaScript</c> on macOS
		/// and returns its standard output. Additional parameters are forwarded to the script's <c>run(argv)</c> function.
		/// </summary>
		/// <param name="script">The JXA source code to execute.</param>
		/// <param name="args">Optional arguments passed to the script.</param>
		/// <returns>The trimmed standard output produced by <c>osascript</c>.</returns>
		public static object Jxa(object script, params object[] args) => RunOsascriptBuiltIn(script, "JavaScript", args);

		private static object RunOsascriptBuiltIn(object script, string language, object[] args)
		{
			if (!script.CoerceString(out var code))
				return DefaultObject;

			if (string.IsNullOrWhiteSpace(code))
				return Errors.ValueErrorOccurred("Script cannot be empty.", script);

			List<string> argList = null;

			if (args is { Length: > 0 })
			{
				argList = new List<string>(args.Length);

				foreach (var arg in args)
				{
					if (!arg.CoerceString(out var str))
						return DefaultObject;

					argList.Add(str);
				}
			}

#if OSX
			var exitCode = code.RunOsascript(out var output, out var error, language, argList, wait: true);

			if (exitCode != 0)
			{
				var detail = !string.IsNullOrEmpty(error) ? error : $"osascript exited with code {exitCode}.";
				return Errors.OSErrorOccurred("", detail, DefaultErrorString);
			}

			return output ?? DefaultErrorString;
#else
			var method = string.Equals(language, "JavaScript", StringComparison.OrdinalIgnoreCase) ? "Ks.Jxa" : "Ks.AppleScript";
			return Errors.ErrorOccurred($"{method} is only supported on macOS.", DefaultErrorString);
#endif
		}
	}
}
