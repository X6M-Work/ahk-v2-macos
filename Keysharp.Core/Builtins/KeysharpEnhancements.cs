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

		internal const string MacNotificationAppleScript = """
			on run argv
				set msgText to item 1 of argv
				set msgTitle to item 2 of argv
				set msgSubtitle to item 3 of argv
				set msgSound to item 4 of argv
				if msgSubtitle is not "" and msgSound is not "" then
					display notification msgText with title msgTitle subtitle msgSubtitle sound name msgSound
				else if msgSubtitle is not "" then
					display notification msgText with title msgTitle subtitle msgSubtitle
				else if msgSound is not "" then
					display notification msgText with title msgTitle sound name msgSound
				else
					display notification msgText with title msgTitle
				end if
			end run
			""";

		internal static List<string> BuildMacNotificationArgs(string text, string title = null, string subtitle = null, string soundName = null)
		{
			var resolvedTitle = !string.IsNullOrEmpty(title)
				? title
				: (Accessors.A_ScriptName is string sn && sn.Length > 0 ? sn : "Keysharp");
			return [text ?? "", resolvedTitle, subtitle ?? "", soundName ?? ""];
		}

		internal static bool TryShowMacNotification(string text, string title = null, string subtitle = null, string soundName = null)
		{
#if OSX
			var args = BuildMacNotificationArgs(text, title, subtitle, soundName);
			return MacNotificationAppleScript.RunOsascript(out _, out _, null, args, wait: true) == 0;
#else
			return false;
#endif
		}

		/// <summary>
		/// Displays a desktop notification. On macOS, delivers a native Notification Center banner via <c>osascript</c>
		/// (even when <c>#NoTrayIcon</c> is active); on other platforms, delegates to <see cref="ToolTips.TrayTip"/>.
		/// </summary>
		/// <param name="text">The notification body text.</param>
		/// <param name="title">Optional notification title (defaults to <c>A_ScriptName</c>).</param>
		/// <param name="subtitle">Optional macOS notification subtitle.</param>
		/// <param name="soundName">Optional macOS notification sound name.</param>
		public static object Notify(object text, object title = null, object subtitle = null, object soundName = null)
		{
			if (!text.CoerceString(out var msgText)
				|| !title.CoerceString(out var msgTitle)
				|| !subtitle.CoerceString(out var msgSubtitle)
				|| !soundName.CoerceString(out var msgSound))
				return DefaultObject;

#if OSX
			var args = BuildMacNotificationArgs(msgText, msgTitle, msgSubtitle, msgSound);
			var exitCode = MacNotificationAppleScript.RunOsascript(out _, out var error, null, args, wait: true);
			if (exitCode != 0)
			{
				var detail = !string.IsNullOrEmpty(error) ? error : $"osascript exited with code {exitCode}.";
				return Errors.OSErrorOccurred("", detail, DefaultErrorObject);
			}
			return DefaultObject;
#else
			return ToolTips.TrayTip(msgText, msgTitle);
#endif
		}

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
