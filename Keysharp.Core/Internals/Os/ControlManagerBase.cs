using Keysharp.Builtins;
namespace Keysharp.Internals.Os
{
	internal abstract class ControlManagerBase
	{
		/// <summary>
		/// The item a MenuSelect path names, or null in <paramref name="menuItem"/> when there is none. False when
		/// an error was raised and the script continued it, and the caller then returns at once without raising
		/// another.
		/// </summary>
		internal static bool TryCollectMenuPath(ReadOnlySpan<object> items, out List<string> path)
		{
			path = [];

			if (items.IsEmpty || !items[0].CoerceString(out var topLevel))
				return false;

			path.Add(topLevel);

			for (var i = 1; i < items.Length; i++)
			{
				if (!items[i].CoerceString(out var step))
					return false;

				if (step.Length > 0)
					path.Add(step);
			}

			return true;
		}

		internal static bool TryParseMenuPosition(string spec, out int zeroBasedIndex)
		{
			if (!string.IsNullOrEmpty(spec)
				&& spec.EndsWith('&')
				&& int.TryParse(spec.AsSpan().Trim('&'), out var oneBased)
				&& oneBased > 0)
			{
				zeroBasedIndex = oneBased - 1;
				return true;
			}

			zeroBasedIndex = -1;
			return false;
		}

		internal static bool TryFindMenuItemIndex(IReadOnlyList<string> titles, string selector, out int matchIndex, out string failureReason)
		{
			matchIndex = -1;
			failureReason = null;

			if (TryParseMenuPosition(selector, out var pos))
			{
				if (pos < titles.Count)
				{
					matchIndex = pos;
					return true;
				}

				failureReason = $"Index {pos + 1} was outside the menu length of {titles.Count}.";
				return false;
			}

			for (var i = 0; i < titles.Count; i++)
			{
				if (MenuMatchHelper(titles[i] ?? string.Empty, selector))
				{
					matchIndex = i;
					return true;
				}
			}

			return true;
		}

		internal static int FindExactListItemIndex(IReadOnlyList<string> items, string target)
		{
			if (items == null || target == null)
				return -1;

			for (var i = 0; i < items.Count; i++)
			{
				if (string.Equals(items[i], target, StringComparison.OrdinalIgnoreCase))
					return i;
			}

			return -1;
		}

		internal static int FindPrefixListItemIndex(IReadOnlyList<string> items, string prefix)
		{
			if (items == null || prefix == null)
				return -1;

			for (var i = 0; i < items.Count; i++)
			{
				if (items[i] != null && items[i].StartsWith(prefix, StringComparison.OrdinalIgnoreCase))
					return i;
			}

			return -1;
		}

		internal static bool TryGetMenuItem(MenuStrip strip, out ToolStripMenuItem menuItem, params object[] items)
		{
			menuItem = null;

			if (!items[0].CoerceString(out var topLevel))
				return false;

			//First get the top level menu.
			if (TryParseMenuPosition(topLevel, out var n))
			{
				if (n < strip.Items.Count)
					menuItem = strip.Items[n] as ToolStripMenuItem;
				else
				{
					_ = Errors.ValueErrorOccurred($"Index {n + 1} was outside the menu length of {strip.Items.Count}.", topLevel);
					return false;
				}
			}
			else
			{
				foreach (ToolStripItem tempItem in strip.Items)
				{
					if (MenuMatchHelper(tempItem.Text, topLevel))
					{
						menuItem = tempItem as ToolStripMenuItem;
						break;
					}
				}
			}

			for (var i = 1; i < items.Length && menuItem != null; i++)
			{
				if (!items[i].CoerceString(out var item))
				{
					menuItem = null;
					return false;
				}

				if (item.Length == 0)
					continue;

				if (TryParseMenuPosition(item, out n))
				{
					if (n < menuItem.DropDownItems.Count)
					{
						menuItem = menuItem.DropDownItems[n] as ToolStripMenuItem;
						continue;
					}
					else
					{
						_ = Errors.ValueErrorOccurred($"Index {n + 1} was outside the menu length of {menuItem.DropDownItems.Count}.", item);
						menuItem = null;
						return false;
					}
				}
				else
				{
					var parent = menuItem;
					menuItem = null;

					foreach (ToolStripItem tempItem in parent.DropDownItems)
					{
						if (MenuMatchHelper(tempItem.Text, item))
						{
							menuItem = tempItem as ToolStripMenuItem;
							break;
						}
					}
				}
			}

			return true;
		}

		internal static bool MenuMatchHelper(string menuText, string match)
		{
			var matchFound = menuText.StartsWith(match, StringComparison.CurrentCultureIgnoreCase);

			if (!matchFound && menuText.Contains('&'))
			{
				var tempsb = new StringBuilder(menuText.Length);

				for (var ii = 0; ii < menuText.Length; ii++)//This logic gotten from AHK to remove every other ampersand.
				{
					if (menuText[ii] == '&')
						ii++;

					if (ii < menuText.Length)
						_ = tempsb.Append(menuText[ii]);
					else
						break;
				}

				menuText = tempsb.ToString();
				matchFound = menuText.StartsWith(match, StringComparison.CurrentCultureIgnoreCase);
			}

			return matchFound;
		}

		internal abstract long ControlAddItem(string str, object ctrl, object title, object text, object excludeTitle, object excludeText);

		internal abstract void ControlChooseIndex(int n, object ctrl, object title, object text, object excludeTitle, object excludeText);

		internal abstract long ControlChooseString(string str, object ctrl, object title, object text, object excludeTitle, object excludeText);

		internal abstract void ControlClick(object ctrlorpos, object title, object text, string whichButton, int clickCount, string options, object excludeTitle, object excludeText);

		internal abstract void ControlDeleteItem(int n, object ctrl, object title, object text, object excludeTitle, object excludeText);

		internal abstract long ControlFindItem(string str, object ctrl, object title, object text, object excludeTitle, object excludeText);

		internal abstract void ControlFocus(object ctrl, object title, object text, object excludeTitle, object excludeText);

		internal abstract long ControlGetChecked(object ctrl, object title, object text, object excludeTitle, object excludeText);

		internal abstract string ControlGetChoice(object ctrl, object title, object text, object excludeTitle, object excludeText);

		internal virtual string ControlGetClassNN(object ctrl, object title, object text, object excludeTitle, object excludeText)
		{
			if (WindowSearch.TrySearchControl(ctrl, title, text, excludeTitle, excludeText, out var item, out var target, true) && item != null)
			{
				var parent = WindowSearch.GetControlReferenceWindow(item, target);
				return Platform.Window.TryEnumerateChildren(parent.Handle, out var controls)
					? WindowQuery.ClassNNs(controls).FirstOrDefault(c => c.Control == item.Handle).ClassNN ?? item.ClassName
					: item.ClassName;
			}

			return DefaultObject;
		}

		internal virtual long ControlGetEnabled(object ctrl, object title, object text, object excludeTitle, object excludeText)
		{
			if (WindowSearch.SearchControl(ctrl, title, text, excludeTitle, excludeText) is WindowInfoBase item)
				return item.Enabled ? 1L : 0L;

			return 0L;
		}

		internal abstract long ControlGetExStyle(object ctrl, object title, object text, object excludeTitle, object excludeText);

		internal abstract long ControlGetFocus(object title, object text, object excludeTitle, object excludeText);

		internal virtual long ControlGetHwnd(object ctrl, object title, object text, object excludeTitle, object excludeText)
		{
			if (WindowSearch.SearchControl(ctrl, title, text, excludeTitle, excludeText) is WindowInfoBase item)
				return item.Handle.ToInt64();
			else
				return 0L;
		}

		internal abstract long ControlGetIndex(object ctrl, object title, object text, object excludeTitle, object excludeText);

		internal abstract object ControlGetItems(object ctrl, object title, object text, object excludeTitle, object excludeText);

		internal abstract void ControlGetPos(ref object outX, ref object outY, ref object outWidth, ref object outHeight, object ctrl = null, object title = null, object text = null, object excludeTitle = null, object excludeText = null);

		internal abstract long ControlGetStyle(object ctrl, object title, object text, object excludeTitle, object excludeText);

		internal abstract string ControlGetText(object ctrl, object title, object text, object excludeTitle, object excludeText);

		internal virtual long ControlGetVisible(object ctrl, object title, object text, object excludeTitle, object excludeText)
		{
			if (WindowSearch.SearchControl(ctrl, title, text, excludeTitle, excludeText) is WindowInfoBase item)
			{
				if (Control.FromHandle(item.Handle) is Control ctrl2)
					return ctrl2.Visible ? 1L : 0L;
				else
					return item.Visible ? 1L : 0L;
			}

			return 0L;
		}

		internal virtual void ControlHide(object ctrl, object title, object text, object excludeTitle, object excludeText) =>
		ShowHideHelper(false, ctrl, title, text, excludeTitle, excludeText);

		internal abstract void ControlHideDropDown(object ctrl, object title, object text, object excludeTitle, object excludeText);

		internal abstract void ControlMove(int x, int y, int width, int height, object ctrl, object title, object text, object excludeTitle, object excludeText);

		internal abstract void ControlSend(string str, object ctrl, object title, object text, object excludeTitle, object excludeText);

		internal abstract void ControlSendText(string str, object ctrl, object title, object text, object excludeTitle, object excludeText);

		internal abstract void ControlSetChecked(object val, object ctrl, object title, object text, object excludeTitle, object excludeText);

		internal abstract void ControlSetEnabled(object val, object ctrl, object title, object text, object excludeTitle, object excludeText);

		//internal abstract void ControlSetText(string str, object ctrl, object title, object text, object excludeTitle, object excludeText);
		internal virtual void ControlSetText(string str, object ctrl, object title, object text, object excludeTitle, object excludeText)
		{
			if (WindowSearch.SearchControl(ctrl, title, text, excludeTitle, excludeText) is WindowInfoBase item)
			{
				if (Control.FromHandle(item.Handle) is Control ctrl2)//No matter what I've tried, sending WM_SETTEXT will not work with buttons, however this method works flawlessly.
					ctrl2.Text = str;
				else
					_ = Platform.Window.TrySetTitle(item.Handle, str);//Just in case... it seems to work on text boxes.

				WindowInfoBase.DoControlDelay();
			}
		}

		internal virtual void ControlShow(object ctrl, object title, object text, object excludeTitle, object excludeText) =>
		ShowHideHelper(true, ctrl, title, text, excludeTitle, excludeText);

		internal abstract void ControlShowDropDown(object ctrl, object title, object text, object excludeTitle, object excludeText);

		internal abstract long EditGetCurrentCol(object ctrl, object title, object text, object excludeTitle, object excludeText);

		internal abstract long EditGetCurrentLine(object ctrl, object title, object text, object excludeTitle, object excludeText);

		internal abstract string EditGetLine(int n, object ctrl, object title, object text, object excludeTitle, object excludeText);

		internal abstract long EditGetLineCount(object ctrl, object title, object text, object excludeTitle, object excludeText);

		internal abstract string EditGetSelectedText(object ctrl, object title, object text, object excludeTitle, object excludeText);

		internal abstract void EditPaste(string str, object ctrl, object title, object text, object excludeTitle, object excludeText);

		internal abstract object ListViewGetContent(string options, object ctrl, object title, object text, object excludeTitle, object excludeText);

		internal abstract void MenuSelect(object title, object text, object menu, object sub1, object sub2, object sub3, object sub4, object sub5, object sub6, object excludeTitle, object excludeText);

		internal abstract void PostMessage(uint msg, nint wparam, nint lparam, object ctrl, object title, object text, object excludeTitle, object excludeText);

		internal abstract long SendMessage(uint msg, object wparam, object lparam, object ctrl, object title, object text, object excludeTitle, object excludeText, int timeout);

		internal static long CountTextLines(string text) =>
			(text ?? string.Empty).AsSpan().Count('\n') + 1L;

		internal static bool TryGetTextLine(string text, int oneBasedLine, out string lineText, out int totalLines)
		{
			lineText = string.Empty;
			totalLines = 0;

			if (oneBasedLine < 1)
				return false;

			var rest = (text ?? string.Empty).AsSpan();

			for (var i = 1; i < oneBasedLine; i++)
			{
				var lineBreak = rest.IndexOf('\n');

				if (lineBreak < 0)
				{
					totalLines = i;
					return false;
				}

				rest = rest[(lineBreak + 1)..];
			}

			var end = rest.IndexOf('\n');
			lineText = (end < 0 ? rest : rest[..end]).TrimEnd('\r').ToString();
			return true;
		}

		internal static long ComputeLineFromOffset(string text, int offset)
		{
			var value = text ?? string.Empty;
			var clamped = Math.Clamp(offset, 0, value.Length);
			return value.AsSpan(0, clamped).Count('\n') + 1L;
		}

		internal static long ComputeColFromOffset(string text, int offset)
		{
			var value = text ?? string.Empty;
			var clamped = Math.Clamp(offset, 0, value.Length);
			var before = value.AsSpan(0, clamped);
			return before.Length - before.LastIndexOf('\n');
		}

		internal static string ApplyTextPaste(string existingText, int selStart, int selLength, string replacement)
		{
			var value = existingText ?? string.Empty;
			var insert = replacement ?? string.Empty;
			var start = Math.Clamp(selStart, 0, value.Length);
			var length = Math.Clamp(selLength, 0, value.Length - start);
			return string.Concat(value.AsSpan(0, start), insert.AsSpan(), value.AsSpan(start + length));
		}

		private static void ShowHideHelper(bool val, object ctrl, object title, object text, object excludeTitle, object excludeText)
		{
			if (WindowSearch.SearchControl(ctrl, title, text, excludeTitle, excludeText) is WindowInfoBase item)
			{
				if (Control.FromHandle(item.Handle) is Control ctrl2)
					ctrl2.Visible = val;
				else
					_ = val ? Platform.Window.TryShow(item.Handle) : Platform.Window.TryHide(item.Handle);

				WindowInfoBase.DoControlDelay();
			}
		}
	}
}
