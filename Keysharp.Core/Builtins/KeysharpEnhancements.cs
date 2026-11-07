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
				return Errors.OSErrorOccurred("", detail, DefaultObject);
			}
			return DefaultObject;
#else
			return ToolTips.TrayTip(msgText, msgTitle);
#endif
		}

		internal static List<string> BuildMacShortcutArgs(string name, bool hasStdinInput = false)
			=> hasStdinInput
				? ["run", name ?? "", "-i", "-"]
				: ["run", name ?? ""];

		/// <summary>
		/// Executes a macOS Shortcut by name via <c>/usr/bin/shortcuts run</c> and returns its standard output.
		/// When <paramref name="input"/> is provided, it is piped to the shortcut's standard input (<c>-i -</c>).
		/// </summary>
		/// <param name="name">The name of the Shortcut in <c>Shortcuts.app</c>.</param>
		/// <param name="input">Optional input string passed to the Shortcut.</param>
		/// <returns>The trimmed standard output produced by the Shortcut.</returns>
		public static object Shortcut(object name, object input = null)
		{
			if (!name.CoerceString(out var shortcutName))
				return DefaultObject;

			if (string.IsNullOrWhiteSpace(shortcutName))
				return Errors.ValueErrorOccurred("Shortcut name cannot be empty.", name, DefaultErrorString);

			string shortcutInput = null;
			if (input != null && !input.CoerceString(out shortcutInput))
				return DefaultObject;

#if OSX
			var exitCode = shortcutName.RunShortcut(out var output, out var error, shortcutInput, wait: true);

			if (exitCode != 0)
			{
				var detail = !string.IsNullOrEmpty(error) ? error : $"shortcuts exited with code {exitCode}.";
				return Errors.OSErrorOccurred("", detail, DefaultErrorString);
			}

			return output ?? DefaultErrorString;
#else
			return Errors.ErrorOccurred("Ks.Shortcut is only supported on macOS.", DefaultErrorString);
#endif
		}

		internal static List<string> BuildMacKeychainGetArgs(string service, string account)
			=> ["find-generic-password", "-s", service ?? "", "-a", account ?? "", "-w"];

		/// <summary>
		/// The <c>add-generic-password</c> line fed to <c>security -i</c> on standard input. Passing the password as
		/// an argument (<c>-w &lt;password&gt;</c>) would expose it to every local process that can list arguments
		/// (<c>ps</c>) for as long as the tool runs. Interactive mode splits the line like a shell: each value is
		/// double-quoted, with <c>\</c> and <c>"</c> escaped. Values must not contain line breaks or NUL
		/// (<see cref="IsKeychainLineSafe"/>), since the line is the command.
		/// </summary>
		internal static string BuildMacKeychainSetCommand(string service, string account, string password)
		{
			static string Quote(string s) => "\"" + (s ?? "").Replace("\\", "\\\\").Replace("\"", "\\\"") + "\"";
			return $"add-generic-password -U -s {Quote(service)} -a {Quote(account)} -w {Quote(password)}\n";
		}

		internal static bool IsKeychainLineSafe(string s)
			=> s == null || s.IndexOfAny(['\r', '\n', '\0']) < 0;

		internal static List<string> BuildMacKeychainDeleteArgs(string service, string account)
			=> ["delete-generic-password", "-s", service ?? "", "-a", account ?? ""];

		internal static List<string> BuildMacSpotlightArgs(string query, string folder = null)
			=> !string.IsNullOrWhiteSpace(folder)
				? ["-onlyin", folder, query ?? ""]
				: [query ?? ""];

		internal static List<string> ParseSpotlightOutput(string output)
		{
			if (string.IsNullOrWhiteSpace(output))
				return [];

			var list = new List<string>();
			foreach (var line in output.SplitLines())
			{
				var trimmed = line.Trim();
				if (trimmed.Length > 0)
					list.Add(trimmed);
			}
			return list;
		}

		/// <summary>
		/// Reads a generic password from the user's macOS Keychain via <c>/usr/bin/security find-generic-password</c>.
		/// </summary>
		/// <param name="service">The Keychain service name (<c>-s</c>).</param>
		/// <param name="account">The Keychain account name (<c>-a</c>).</param>
		/// <returns>The secret password string.</returns>
		public static object KeychainGet(object service, object account)
		{
			if (!service.CoerceString(out var svc) || !account.CoerceString(out var acct))
				return DefaultObject;

			if (string.IsNullOrWhiteSpace(svc) || string.IsNullOrWhiteSpace(acct))
				return Errors.ValueErrorOccurred("Keychain service and account cannot be empty.", $"{svc}:{acct}", DefaultErrorString);

#if OSX
			var exitCode = "/usr/bin/security".RunMacCommand(BuildMacKeychainGetArgs(svc, acct), out var output, out var error, wait: true);
			if (exitCode != 0)
			{
				var detail = !string.IsNullOrEmpty(error) ? error : $"security exited with code {exitCode}.";
				return Errors.OSErrorOccurred("", detail, DefaultErrorString);
			}

			return output ?? DefaultErrorString;
#else
			return Errors.ErrorOccurred("Ks.KeychainGet is only supported on macOS.", DefaultErrorString);
#endif
		}

		/// <summary>
		/// Stores or updates a generic password in the user's macOS Keychain via <c>/usr/bin/security add-generic-password -U</c>.
		/// The command is sent on standard input (<c>security -i</c>), so the password never appears on a command line.
		/// </summary>
		/// <param name="service">The Keychain service name (<c>-s</c>).</param>
		/// <param name="account">The Keychain account name (<c>-a</c>).</param>
		/// <param name="password">The secret password to store (<c>-w</c>); it cannot contain line breaks.</param>
		public static object KeychainSet(object service, object account, object password)
		{
			if (!service.CoerceString(out var svc) || !account.CoerceString(out var acct) || !password.CoerceString(out var pwd))
				return DefaultObject;

			if (string.IsNullOrWhiteSpace(svc) || string.IsNullOrWhiteSpace(acct))
				return Errors.ValueErrorOccurred("Keychain service and account cannot be empty.", $"{svc}:{acct}", DefaultObject);

#if OSX
			if (!IsKeychainLineSafe(svc) || !IsKeychainLineSafe(acct) || !IsKeychainLineSafe(pwd))
				return Errors.ValueErrorOccurred("Keychain service, account and password cannot contain line breaks or NUL.", null, DefaultObject);

			// Interactive mode keeps going after a failed command, so its exit code alone is not
			// enough: anything on stderr is the failure.
			var exitCode = "/usr/bin/security".RunMacCommand(["-i"], out _, out var error, wait: true,
				standardInput: BuildMacKeychainSetCommand(svc, acct, pwd));
			if (exitCode != 0 || !string.IsNullOrEmpty(error))
			{
				var detail = !string.IsNullOrEmpty(error) ? error : $"security exited with code {exitCode}.";
				return Errors.OSErrorOccurred("", detail, DefaultObject);
			}

			return 1L;
#else
			return Errors.ErrorOccurred("Ks.KeychainSet is only supported on macOS.", DefaultObject);
#endif
		}

		/// <summary>
		/// Deletes a generic password from the user's macOS Keychain via <c>/usr/bin/security delete-generic-password</c>.
		/// </summary>
		/// <param name="service">The Keychain service name (<c>-s</c>).</param>
		/// <param name="account">The Keychain account name (<c>-a</c>).</param>
		public static object KeychainDelete(object service, object account)
		{
			if (!service.CoerceString(out var svc) || !account.CoerceString(out var acct))
				return DefaultObject;

			if (string.IsNullOrWhiteSpace(svc) || string.IsNullOrWhiteSpace(acct))
				return Errors.ValueErrorOccurred("Keychain service and account cannot be empty.", $"{svc}:{acct}", DefaultObject);

#if OSX
			var exitCode = "/usr/bin/security".RunMacCommand(BuildMacKeychainDeleteArgs(svc, acct), out _, out var error, wait: true);
			if (exitCode != 0)
			{
				var detail = !string.IsNullOrEmpty(error) ? error : $"security exited with code {exitCode}.";
				return Errors.OSErrorOccurred("", detail, DefaultObject);
			}

			return 1L;
#else
			return Errors.ErrorOccurred("Ks.KeychainDelete is only supported on macOS.", DefaultObject);
#endif
		}

		/// <summary>
		/// Searches the macOS Spotlight metadata index via <c>/usr/bin/mdfind</c> and returns an <see cref="Array"/> of matching file paths.
		/// </summary>
		/// <param name="query">The Spotlight query expression or search string.</param>
		/// <param name="folder">Optional directory path to restrict the search (<c>-onlyin</c>).</param>
		public static object Spotlight(object query, object folder = null)
		{
			if (!query.CoerceString(out var q))
				return DefaultObject;

			if (string.IsNullOrWhiteSpace(q))
				return Errors.ValueErrorOccurred("Spotlight query cannot be empty.", query, DefaultObject);

			string dir = null;
			if (folder != null && !folder.CoerceString(out dir))
				return DefaultObject;

#if OSX
			var exitCode = "/usr/bin/mdfind".RunMacCommand(BuildMacSpotlightArgs(q, dir), out var output, out var error, wait: true);
			if (exitCode != 0)
			{
				var detail = !string.IsNullOrEmpty(error) ? error : $"mdfind exited with code {exitCode}.";
				return Errors.OSErrorOccurred("", detail, DefaultObject);
			}

			var matches = ParseSpotlightOutput(output);
			var arr = new Array { Capacity = matches.Count };
			var list = arr as IList;
			foreach (var item in matches)
				list.Add(item);
			return arr;
#else
			return Errors.ErrorOccurred("Ks.Spotlight is only supported on macOS.", DefaultObject);
#endif
		}

		/// <summary>
		/// Reveals a file or directory in the desktop file manager (Finder on macOS via <c>/usr/bin/open -R</c>,
		/// File Explorer on Windows via <c>explorer.exe /select</c>, or <c>xdg-open</c> on Linux).
		/// </summary>
		/// <param name="path">The file or directory path to reveal.</param>
		public static object RevealInFinder(object path)
		{
			if (!path.CoerceString(out var p))
				return DefaultObject;

			if (string.IsNullOrWhiteSpace(p))
				return Errors.ValueErrorOccurred("Path cannot be empty.", path, DefaultObject);

			var fullPath = Path.GetFullPath(p);
			if (!File.Exists(fullPath) && !Directory.Exists(fullPath))
				return Errors.TargetErrorOccurred($"Path does not exist: {fullPath}");

#if OSX
			var exitCode = "/usr/bin/open".RunMacCommand(["-R", fullPath], out _, out var error, wait: true);
			if (exitCode != 0)
			{
				var detail = !string.IsNullOrEmpty(error) ? error : $"open -R exited with code {exitCode}.";
				return Errors.OSErrorOccurred("", detail, DefaultObject);
			}
			return 1L;
#elif WINDOWS
			using var proc = Process.Start(new ProcessStartInfo
			{
				FileName = "explorer.exe",
				Arguments = $"/select,\"{fullPath}\"",
				UseShellExecute = false,
				CreateNoWindow = true
			});
			return 1L;
#else
			var parent = Directory.Exists(fullPath) ? fullPath : (Path.GetDirectoryName(fullPath) ?? fullPath);
			using var proc = Process.Start(new ProcessStartInfo
			{
				FileName = "xdg-open",
				ArgumentList = { parent },
				UseShellExecute = false,
				CreateNoWindow = true
			});
			return 1L;
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
