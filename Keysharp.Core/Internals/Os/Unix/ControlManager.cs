using Keysharp.Builtins;
#if !WINDOWS
using Keysharp.Internals.Os.Windows;
using static Keysharp.Internals.Input.Keyboard.VirtualKeys;
using static Keysharp.Builtins.KeysharpListView;

namespace Keysharp.Internals.Os.Unix
{
	/// <summary>
	/// Concrete implementation of ControlManager for the linux platfrom.
	/// </summary>
	internal class ControlManager : ControlManagerBase
	{
#if OSX
		private static bool TryResolveForeignMacControlTarget(
			object ctrl,
			object title,
			object text,
			object excludeTitle,
			object excludeText,
			out Keysharp.Internals.Window.MacOS.MacNativeWindow nativeWin,
			out string selector)
		{
			nativeWin = default;
			selector = null;

			if (ctrl is not string s || string.IsNullOrWhiteSpace(s))
				return false;

			if (WindowSearch.SearchWindow(title, text, excludeTitle, excludeText, false) is not WindowInfoBase win)
				return false;

			if (Control.FromHandle(win.Handle) != null)
				return false;

			if (!Keysharp.Internals.Window.MacOS.MacNativeWindows.TryGetWindowInfo(win.Handle, out nativeWin)
				|| nativeWin.OwnerPid == Environment.ProcessId)
				return false;

			selector = s;
			return true;
		}
#endif

		/// <summary>Finds the script's own control, raising TargetError for a foreign control.</summary>
		private static Control OwnControl(object ctrl, object title, object text, object excludeTitle, object excludeText)
		{
			if (WindowSearch.SearchControl(ctrl, title, text, excludeTitle, excludeText) is not WindowInfoBase item)
				return null;

			if (Control.FromHandle(item.Handle) is Control control)
				return control;

			_ = Errors.TargetErrorOccurred($"{item.ClassName} belongs to another program, and only the script's own controls can be reached here", title, text, excludeTitle, excludeText);
			return null;
		}

		private static object WrongClass(Control control, string classes, object ret = null)
			=> Errors.TargetErrorOccurred($"Class name {Platform.Window.GetClassName(control.Handle)} did not contain {classes}", ret);

		/// <summary>The items of a ListBox, DDL or ComboBox; null for any other control.</summary>
		private static ListControlItems ListItems(Control control) => control switch
		{
			KeysharpListBox lb => lb.Items,
			KeysharpComboBox cb => cb.Items,
			_ => null
		};

		//AHK notifies the parent even when the selection stays the same or is cleared.
		private static void Choose(Control control, int index)
		{
			var list = (Gui.List)control.GetGuiControl();
			_ = list.ChooseItem(index + 1L, true);

			if (control is KeysharpListBox)
			{
				list.Lb_SelectedIndexChanged(control, EventArgs.Empty);
				list._control_DoubleClick(control, EventArgs.Empty);
			}
			else
				list.Cmb_SelectedIndexChanged(control, EventArgs.Empty);

			WindowInfoBase.DoControlDelay();
		}

		internal override long ControlAddItem(string str, object ctrl, object title, object text, object excludeTitle, object excludeText)
		{
			if (OwnControl(ctrl, title, text, excludeTitle, excludeText) is not Control control)
				return 0L;

			if (ListItems(control) is not ListControlItems items || control.GetGuiControl() is not Gui.List list)
				return (long)WrongClass(control, "Combo or List", DefaultErrorLong);

			//As CB_ADDSTRING and LB_ADDSTRING, the position the item took, which a Sort list chooses.
			var index = items.IndexFor(str);
			_ = list.Add(str);
			WindowInfoBase.DoControlDelay();
			return index + 1L;
		}

		internal override void ControlChooseIndex(int n, object ctrl, object title, object text, object excludeTitle, object excludeText)
		{
			if (n < 0)
			{
				_ = Errors.InvalidParameterErrorOccurred(1, "ControlChooseIndex", n);
				return;
			}

#if OSX
			if (TryResolveForeignMacControlTarget(ctrl, title, text, excludeTitle, excludeText, out var nativeWin, out var selector))
			{
				if (Keysharp.Internals.Window.MacOS.MacAccessibility.TryChooseControlIndex(
					nativeWin,
					selector,
					n,
					out var foundControl,
					out var unsupportedClass,
					out var invalidParameter,
					out var failureReason))
				{
					WindowInfoBase.DoControlDelay();
					return;
				}

				if (!foundControl)
					_ = Errors.TargetErrorOccurred($"Could not get control {selector}", title, text, excludeTitle, excludeText);
				else if (unsupportedClass)
					_ = Errors.TargetErrorOccurred($"Control {selector} did not match Combo, List or Tab", title, text, excludeTitle, excludeText);
				else if (invalidParameter)
					_ = Errors.InvalidParameterErrorOccurred(1, "ControlChooseIndex", n);
				else
					_ = Errors.ErrorOccurred(failureReason ?? "Failed");
				return;
			}
#endif

			if (OwnControl(ctrl, title, text, excludeTitle, excludeText) is not Control control)
				return;

			n--;

			if (control is TabControl tc)
			{
				if (n < 0 || n >= tc.Pages.Count)
				{
					_ = Errors.InvalidParameterErrorOccurred(1, "ControlChooseIndex", n + 1);
					return;
				}

				tc.SelectedIndex = n;
				WindowInfoBase.DoControlDelay();
			}
			else if (ListItems(control) is ListControlItems items)
			{
				//0 clears the selection, as CB_SETCURSEL and LB_SETCURSEL do for -1.
				if (n < -1 || n >= items.Count)
					_ = Errors.ErrorOccurred("Failed");
				else
					Choose(control, n);
			}
			else
				_ = WrongClass(control, "Combo, List or Tab");
		}

		internal override long ControlChooseString(string str, object ctrl, object title, object text, object excludeTitle, object excludeText)
		{
#if OSX
			if (TryResolveForeignMacControlTarget(ctrl, title, text, excludeTitle, excludeText, out var nativeWin, out var selector))
			{
				if (Keysharp.Internals.Window.MacOS.MacAccessibility.TryChooseControlString(
					nativeWin,
					selector,
					str,
					out var chosenIndex,
					out var foundControl,
					out var unsupportedClass))
				{
					WindowInfoBase.DoControlDelay();
					return chosenIndex;
				}

				if (!foundControl)
					return (long)Errors.TargetErrorOccurred($"Could not get control {selector}", title, text, excludeTitle, excludeText, DefaultErrorLong);
				if (unsupportedClass)
					return (long)Errors.TargetErrorOccurred($"Control {selector} did not match Combo or List", title, text, excludeTitle, excludeText, DefaultErrorLong);
				return (long)Errors.TargetErrorOccurred($"No item starts with \"{str}\"", title, text, excludeTitle, excludeText, DefaultErrorLong);
			}
#endif
			if (OwnControl(ctrl, title, text, excludeTitle, excludeText) is not Control control)
				return 0L;

			if (ListItems(control) == null)
				return (long)WrongClass(control, "Combo or List", DefaultErrorLong);

			var index = ((ListControl)control).FindString(str);

			if (index < 0)
				return (long)Errors.TargetErrorOccurred($"No item starts with \"{str}\"", title, text, excludeTitle, excludeText, DefaultErrorLong);

			Choose(control, index);
			return index + 1L;
		}

		internal override void ControlClick(object ctrlorpos, object title, object text, string whichButton, int clickCount, string options, object excludeTitle, object excludeText)
		{
			var winx = int.MinValue;
			var winy = int.MinValue;
			var ctrlx = int.MinValue;
			var ctrly = int.MinValue;
			var vk = HookThread.ConvertMouseButton(whichButton);
			var posoverride = options?.Contains("pos", StringComparison.OrdinalIgnoreCase) ?? false;
			bool d = false, u = false;
			var posAppliedToChild = false;

			if (!string.IsNullOrEmpty(options))
			{
				foreach (Range r in options.AsSpan().SplitAny(Spaces))
				{
					var opt = options.AsSpan(r).Trim();

					if (opt.Length > 0)
					{
						if (opt.Equals("d", StringComparison.OrdinalIgnoreCase))
							d = true;
						else if (opt.Equals("u", StringComparison.OrdinalIgnoreCase))
							u = true;
						else if (Options.TryParse(opt, "x", ref ctrlx)) { }
						else if (Options.TryParse(opt, "y", ref ctrly)) { }
					}
				}
			}

			if (d) u = false;
			if (u) d = false;

			if (ctrlorpos is string s && s.StartsWith("x", StringComparison.OrdinalIgnoreCase) && s.Contains(' ') && s.Contains('y', StringComparison.OrdinalIgnoreCase))
			{
				foreach (Range r in s.AsSpan().SplitAny(Spaces))
				{
					var opt = s.AsSpan(r).Trim();

					if (opt.Length > 0)
					{
						if (Options.TryParse(opt, "x", ref winx)) { }
						else if (Options.TryParse(opt, "y", ref winy)) { }
					}
				}
			}

			WindowInfoBase item = null;
			WindowInfoBase target = null;
			var getctrlbycoords = false;

			if (ctrlorpos.IsNullOrEmpty())
			{
				item = target = WindowSearch.SearchWindow(title, text, excludeTitle, excludeText, true);
			}
			else if (!posoverride)
			{
#if OSX
				if (winx == int.MinValue && winy == int.MinValue
					&& TryResolveForeignMacControlTarget(ctrlorpos, title, text, excludeTitle, excludeText, out var foreignWin, out var foreignSelector))
				{
					if (!TryMapMacControlClickInput(vk, out var isWheelForeign, out var wheelDeltaForeign, out var horizontalForeign, out var foreignButton))
					{
						_ = Errors.ValueErrorOccurred($"Invalid macOS ControlClick button '{whichButton}'. Expected Left, Right, Middle, X1, X2, WheelUp, WheelDown, WheelLeft or WheelRight.");
						return;
					}

					if (clickCount < 1)
						return;

					bool foundForeign;
					var okForeign = isWheelForeign
						? Keysharp.Internals.Window.MacOS.MacAccessibility.TryScrollControl(foreignWin, foreignSelector, wheelDeltaForeign, horizontalForeign, clickCount, ctrlx, ctrly, out foundForeign)
						: Keysharp.Internals.Window.MacOS.MacAccessibility.TryClickControl(foreignWin, foreignSelector, foreignButton, clickCount, ctrlx, ctrly, out foundForeign, sendDown: !u, sendUp: !d);

					if (okForeign)
					{
						WindowInfoBase.DoControlDelay();
						return;
					}

					if (!foundForeign)
						_ = Errors.TargetErrorOccurred($"Could not get control {ctrlorpos}", title, text, excludeTitle, excludeText);
					return;
				}
#endif
				if (!WindowSearch.TrySearchControl(ctrlorpos, title, text, excludeTitle, excludeText, out item, out target))
					return;

				if (item == null)
				{
					if (winx != int.MinValue && winy != int.MinValue)
						getctrlbycoords = true;
					else
						_ = Errors.TargetErrorOccurred($"Could not get control {ctrlorpos}", title, text, excludeTitle, excludeText);
				}
			}
			else
			{
				if (winx != int.MinValue && winy != int.MinValue)
					getctrlbycoords = true;
			}

			if (getctrlbycoords)
			{
				item = target ?? WindowSearch.SearchWindow(title, text, excludeTitle, excludeText, true);
				if (item != null)
				{
					var pt = new POINT(winx, winy);
					item.ClientToScreen(ref pt);
					var pah = new PointAndHwnd(pt);
					Platform.Window.ChildFindPoint(item.Handle, pah);
					if (pah.hwndFound != 0)
					{
						item = WindowQuery.CreateWindow(pah.hwndFound);
						if (ctrlx == int.MinValue || ctrly == int.MinValue)
						{
							ctrlx = pt.X - pah.rectFound.Left;
							ctrly = pt.Y - pah.rectFound.Top;
						}
						posAppliedToChild = true;
					}
				}
			}

			if (item == null || clickCount < 1)
				return;

			var size = item.Size;
			var clickX = ctrlx != int.MinValue ? ctrlx : size.Width / 2;
			var clickY = ctrly != int.MinValue ? ctrly : size.Height / 2;

			if (!posAppliedToChild && winx != int.MinValue && winy != int.MinValue)
			{
				clickX = winx;
				clickY = winy;
			}

			var clickPoint = new Point(clickX, clickY);
			var vkIsWheel = MouseUtils.IsWheelVK(vk);

			if (item is ControlInfo controlInfo && vk == VK_LBUTTON && !vkIsWheel && !d && !u && controlInfo.TryInvokeDefaultClick(clickPoint, clickCount))
			{
				WindowInfoBase.DoControlDelay();
				return;
			}

#if LINUX
			if (!Platform.Desktop.IsX11Available)
				return;

			uint button;
			if (vk == VK_LBUTTON) button = 1;
			else if (vk == VK_RBUTTON) button = 3;
			else if (vk == VK_MBUTTON) button = 2;
			else if (vk == VK_XBUTTON1) button = 8;
			else if (vk == VK_XBUTTON2) button = 9;
			else if (vk == VK_WHEEL_UP) button = 4;
			else if (vk == VK_WHEEL_DOWN) button = 5;
			else if (vk == VK_WHEEL_LEFT) button = 6;
			else if (vk == VK_WHEEL_RIGHT) button = 7;
			else return;

#elif OSX
			if (!TryMapMacControlClickInput(vk, out var isWheel, out var wheelDelta, out var horizontalWheel, out var button))
			{
				_ = Errors.ValueErrorOccurred($"Invalid macOS ControlClick button '{whichButton}'. Expected Left, Right, Middle, X1, X2, WheelUp, WheelDown, WheelLeft or WheelRight.");
				return;
			}

			var acted = isWheel
				? Platform.Window.TryScroll(item.Handle, clickPoint, wheelDelta, horizontalWheel, clickCount)
				: Platform.Window.TryClick(item.Handle, clickPoint, button, clickCount, !u, !d);

			if (acted)
				WindowInfoBase.DoControlDelay();
#else
#error Unsupported platform. Only WINDOWS, LINUX, and OSX are supported.
#endif

#if LINUX
			for (var i = 0; i < clickCount; i++)
			{
				if (vkIsWheel || !u)
				{
					if (!SendX11MouseEvent(item.Handle, button, clickPoint, true)) return;
					WindowInfoBase.DoControlDelay();
				}

				if (vkIsWheel || !d)
				{
					if (!SendX11MouseEvent(item.Handle, button, clickPoint, false)) return;
					WindowInfoBase.DoControlDelay();
				}
			}
#endif
		}

#if LINUX
		private static bool SendX11MouseEvent(nint handle, uint button, Point location, bool down)
			=> Keysharp.Internals.Window.Linux.Wayland.DesktopBackend.X11
				.TrySendWindowButton(handle, location, button, down);
#elif OSX
		internal static bool TryMapMacControlClickInput(
			uint vk,
			out bool isWheel,
			out short wheelDelta,
			out bool horizontalWheel,
			out uint mouseButton)
		{
			isWheel = false;
			wheelDelta = 0;
			horizontalWheel = false;
			mouseButton = 0;

			switch (vk)
			{
				case VK_LBUTTON:
					mouseButton = 1;
					return true;
				case VK_RBUTTON:
					mouseButton = 2;
					return true;
				case VK_MBUTTON:
					mouseButton = 3;
					return true;
				case VK_XBUTTON1:
					mouseButton = 4;
					return true;
				case VK_XBUTTON2:
					mouseButton = 5;
					return true;
				case VK_WHEEL_UP:
					isWheel = true;
					wheelDelta = (short)MouseUtils.WHEEL_DELTA;
					return true;
				case VK_WHEEL_DOWN:
					isWheel = true;
					wheelDelta = (short)-MouseUtils.WHEEL_DELTA;
					return true;
				case VK_WHEEL_LEFT:
					isWheel = true;
					horizontalWheel = true;
					wheelDelta = (short)-MouseUtils.WHEEL_DELTA;
					return true;
				case VK_WHEEL_RIGHT:
					isWheel = true;
					horizontalWheel = true;
					wheelDelta = (short)MouseUtils.WHEEL_DELTA;
					return true;
				default:
					return false;
			}
		}
#endif

		internal override void ControlDeleteItem(int n, object ctrl, object title, object text, object excludeTitle, object excludeText)
		{
			if (OwnControl(ctrl, title, text, excludeTitle, excludeText) is not Control control)
				return;

			if (ListItems(control) is not ListControlItems items || control.GetGuiControl() is not Gui.List list)
			{
				_ = WrongClass(control, "Combo or List");
				return;
			}

			if (n < 1 || n > items.Count)
			{
				_ = Errors.TargetErrorOccurred($"Item {n} does not exist in a list of {items.Count}", title, text, excludeTitle, excludeText);
				return;
			}

			_ = list.Delete((long)n);
			WindowInfoBase.DoControlDelay();
		}

		internal override long ControlFindItem(string str, object ctrl, object title, object text, object excludeTitle, object excludeText)
		{
#if OSX
			if (TryResolveForeignMacControlTarget(ctrl, title, text, excludeTitle, excludeText, out var nativeWin, out var selector))
			{
				if (Keysharp.Internals.Window.MacOS.MacAccessibility.TryGetControlItems(nativeWin, selector, out var foreignItems, out var foundControl, out var unsupportedClass))
				{
					var foreignIdx = FindExactListItemIndex(foreignItems, str);
					return foreignIdx >= 0
						? foreignIdx + 1L
						: (long)Errors.TargetErrorOccurred($"Could not search for combo or list box item string {str}", title, text, excludeTitle, excludeText, DefaultErrorLong);
				}

				if (!foundControl)
					return (long)Errors.TargetErrorOccurred($"Could not get control {selector}", title, text, excludeTitle, excludeText, DefaultErrorLong);
				if (unsupportedClass)
					return (long)Errors.TargetErrorOccurred($"Control {selector} did not match Combo or List", title, text, excludeTitle, excludeText, DefaultErrorLong);
				return (long)Errors.TargetErrorOccurred($"Could not search for combo or list box item string {str}", title, text, excludeTitle, excludeText, DefaultErrorLong);
			}
#endif
			if (OwnControl(ctrl, title, text, excludeTitle, excludeText) is not Control control)
				return 0L;

			if (ListItems(control) == null)
				return (long)WrongClass(control, "Combo or List", DefaultErrorLong);

			var index = ((ListControl)control).FindStringExact(str);
			return index >= 0 ? index + 1L : (long)Errors.TargetErrorOccurred($"Could not search for combo or list box item string {str}", title, text, excludeTitle, excludeText, DefaultErrorLong);
		}

		internal override void ControlFocus(object ctrl, object title, object text, object excludeTitle, object excludeText)
		{
#if OSX
			if (TryResolveForeignMacControlTarget(ctrl, title, text, excludeTitle, excludeText, out var nativeWin, out var selector))
			{
				if (Keysharp.Internals.Window.MacOS.MacAccessibility.TryFocusControl(nativeWin, selector, out var foundControl))
				{
					WindowInfoBase.DoControlDelay();
					return;
				}

				if (!foundControl)
					_ = Errors.TargetErrorOccurred($"Could not get control {selector}", title, text, excludeTitle, excludeText);
				else
					_ = WindowHelper.WindowOperationUnsupported("ControlFocus");
				return;
			}
#endif
			if (WindowSearch.SearchControl(ctrl, title, text, excludeTitle, excludeText) is not WindowInfoBase item)
				return;

			if (Control.FromHandle(item.Handle) is Control control)
				control.Focus();
#if LINUX
			else if (!Keysharp.Internals.Window.Linux.Wayland.DesktopBackend.X11.TryFocusChildWindow(item.Handle))
#else
			else
#endif
			{
				_ = WindowHelper.WindowOperationUnsupported("ControlFocus");
				return;
			}

			WindowInfoBase.DoControlDelay();
		}

		internal override long ControlGetChecked(object ctrl, object title, object text, object excludeTitle, object excludeText)
		{
#if OSX
			if (TryResolveForeignMacControlTarget(ctrl, title, text, excludeTitle, excludeText, out var nativeWin, out var selector))
			{
				if (Keysharp.Internals.Window.MacOS.MacAccessibility.TryGetControlChecked(nativeWin, selector, out var isChecked, out var foundControl))
					return isChecked ? 1L : 0L;

				if (!foundControl)
					return (long)Errors.TargetErrorOccurred($"Could not get control {selector}", title, text, excludeTitle, excludeText, DefaultErrorLong);

				return 0L;
			}
#endif
			//As BM_GETCHECK, only a checked state counts; another control is unchecked.
			return OwnControl(ctrl, title, text, excludeTitle, excludeText) switch
			{
				CheckBox cb => cb.Checked == true ? 1L : 0L,
				RadioButton rb => rb.Checked ? 1L : 0L,
				_ => 0L
			};
		}

#if OSX
		internal override string ControlGetClassNN(object ctrl, object title, object text, object excludeTitle, object excludeText)
		{
			if (TryResolveForeignMacControlTarget(ctrl, title, text, excludeTitle, excludeText, out var nativeWin, out var selector))
			{
				if (Keysharp.Internals.Window.MacOS.MacAccessibility.TryGetControlClassNN(nativeWin, selector, out var classNN))
					return classNN;

				return (string)Errors.TargetErrorOccurred($"Could not get control {selector}", title, text, excludeTitle, excludeText, DefaultErrorString);
			}

			return base.ControlGetClassNN(ctrl, title, text, excludeTitle, excludeText);
		}

		internal override long ControlGetEnabled(object ctrl, object title, object text, object excludeTitle, object excludeText)
		{
			if (TryResolveForeignMacControlTarget(ctrl, title, text, excludeTitle, excludeText, out var nativeWin, out var selector))
			{
				if (Keysharp.Internals.Window.MacOS.MacAccessibility.TryGetControlEnabled(nativeWin, selector, out var enabled, out var foundControl))
					return enabled ? 1L : 0L;

				if (!foundControl)
					return (long)Errors.TargetErrorOccurred($"Could not get control {selector}", title, text, excludeTitle, excludeText, DefaultErrorLong);

				return 0L;
			}

			return base.ControlGetEnabled(ctrl, title, text, excludeTitle, excludeText);
		}
#endif

		internal override string ControlGetChoice(object ctrl, object title, object text, object excludeTitle, object excludeText)
		{
#if OSX
			if (TryResolveForeignMacControlTarget(ctrl, title, text, excludeTitle, excludeText, out var nativeWin, out var selector))
			{
				if (Keysharp.Internals.Window.MacOS.MacAccessibility.TryGetControlChoice(nativeWin, selector, out var choice, out var foundControl, out var unsupportedClass))
					return choice;

				if (!foundControl)
					return (string)Errors.TargetErrorOccurred($"Could not get control {selector}", title, text, excludeTitle, excludeText, DefaultErrorString);
				if (unsupportedClass)
					return (string)Errors.TargetErrorOccurred($"Control {selector} did not match Combo or List", title, text, excludeTitle, excludeText, DefaultErrorString);
				return (string)Errors.ErrorOccurred($"Could not get selected item string for combo or list box in window with criteria: title: {title}, text: {text}, exclude title: {excludeTitle}, exclude text: {excludeText}", DefaultErrorString);
			}
#endif
			if (OwnControl(ctrl, title, text, excludeTitle, excludeText) is not Control control)
				return DefaultObject;

			if (ListItems(control) is not ListControlItems items)
				return (string)WrongClass(control, "Combo or List", DefaultErrorString);

			var index = ((ListControl)control).SelectedIndex;

			if (index < 0 || index >= items.Count)
				return (string)Errors.ErrorOccurred($"Could not get selected item string for combo or list box in window with criteria: title: {title}, text: {text}, exclude title: {excludeTitle}, exclude text: {excludeText}", DefaultErrorString);

			return items[index]?.ToString() ?? "";
		}

		internal override long ControlGetExStyle(object ctrl, object title, object text, object excludeTitle, object excludeText) => WindowSearch.SearchControl(ctrl, title, text, excludeTitle, excludeText) is WindowInfoBase item ? item.ExStyle : 0L;

		internal override long ControlGetFocus(object title, object text, object excludeTitle, object excludeText)
		{
			if (WindowSearch.SearchWindow(title, text, excludeTitle, excludeText, true) is WindowInfoBase item
				&& Control.FromHandle(item.Handle) is Form form)
				return form.CheckedInvoke(() => form.ActiveControl?.Handle.ToInt64() ?? 0L, true);

			return 0L;
		}

		internal override long ControlGetIndex(object ctrl, object title, object text, object excludeTitle, object excludeText)
		{
#if OSX
			if (TryResolveForeignMacControlTarget(ctrl, title, text, excludeTitle, excludeText, out var nativeWin, out var selector))
			{
				if (Keysharp.Internals.Window.MacOS.MacAccessibility.TryGetControlIndex(nativeWin, selector, out var index, out var foundControl, out var unsupportedClass))
					return index;

				if (!foundControl)
					return (long)Errors.TargetErrorOccurred($"Could not get control {selector}", title, text, excludeTitle, excludeText, DefaultErrorLong);
				if (unsupportedClass)
					return (long)Errors.TargetErrorOccurred($"Control {selector} did not match Combo, List or Tab", title, text, excludeTitle, excludeText, DefaultErrorLong);
				return 0L;
			}
#endif
			return OwnControl(ctrl, title, text, excludeTitle, excludeText) switch
			{
				null => 0L,
				TabControl tc => tc.SelectedIndex + 1L,
				Control control when ListItems(control) != null => ((ListControl)control).SelectedIndex + 1L,
				Control control => (long)WrongClass(control, "Combo, List or Tab", DefaultErrorLong)
			};
		}

		internal override object ControlGetItems(object ctrl, object title, object text, object excludeTitle, object excludeText)
		{
#if OSX
			if (TryResolveForeignMacControlTarget(ctrl, title, text, excludeTitle, excludeText, out var nativeWin, out var selector))
			{
				if (Keysharp.Internals.Window.MacOS.MacAccessibility.TryGetControlItems(nativeWin, selector, out var foreignItems, out var foundControl, out var unsupportedClass))
					return new Keysharp.Builtins.Array(foreignItems.Cast<object>().ToList());

				if (!foundControl)
					return Errors.TargetErrorOccurred($"Could not get control {selector}", title, text, excludeTitle, excludeText);
				if (unsupportedClass)
					return Errors.TargetErrorOccurred($"Control {selector} did not match Combo or List", title, text, excludeTitle, excludeText);
				return new Keysharp.Builtins.Array();
			}
#endif
			if (OwnControl(ctrl, title, text, excludeTitle, excludeText) is not Control control)
				return new Keysharp.Builtins.Array();

			if (ListItems(control) is not ListControlItems items)
				return WrongClass(control, "Combo or List");

			var texts = new List<object>(items.Count);

			foreach (var item in items)
				texts.Add(item?.ToString() ?? "");

			return new Keysharp.Builtins.Array(texts);
		}

		internal override void ControlGetPos(ref object outX, ref object outY, ref object outWidth, ref object outHeight, object ctrl = null, object title = null, object text = null, object excludeTitle = null, object excludeText = null)
		{
#if OSX
			if (TryResolveForeignMacControlTarget(ctrl, title, text, excludeTitle, excludeText, out var nativeWin, out var selector))
			{
				if (Keysharp.Internals.Window.MacOS.MacAccessibility.TryGetControlPos(nativeWin, selector, out var relBounds, out var foundControl))
				{
					outX = (long)relBounds.X;
					outY = (long)relBounds.Y;
					outWidth = (long)relBounds.Width;
					outHeight = (long)relBounds.Height;
					return;
				}

				outX = 0L;
				outY = 0L;
				outWidth = 0L;
				outHeight = 0L;
				if (!foundControl)
					_ = Errors.TargetErrorOccurred($"Could not get control {selector}", title, text, excludeTitle, excludeText);
				return;
			}
#endif
			if (WindowSearch.TrySearchControl(ctrl, title, text, excludeTitle, excludeText, out var item, out var target, true)
				&& item != null && Control.FromHandle(item.Handle) is Control control)
			{
				var bounds = control.GetScreenBounds(true);
				var origin = WindowSearch.GetControlReferenceWindow(item, target).ClientToScreen();
				outX = (long)(bounds.X - origin.X);
				outY = (long)(bounds.Y - origin.Y);
				outWidth = control.Width;
				outHeight = control.Height;
				return;
			}

			outX = 0L;
			outY = 0L;
			outWidth = 0L;
			outHeight = 0L;
		}

		internal override void ControlMove(int x, int y, int width, int height, object ctrl, object title, object text, object excludeTitle, object excludeText)
		{
			if (!WindowSearch.TrySearchControl(ctrl, title, text, excludeTitle, excludeText, out var item, out var target, true) || item == null)
				return;

			var setPos = x != int.MinValue || y != int.MinValue;
			var setSize = width != int.MinValue || height != int.MinValue;

			if (Control.FromHandle(item.Handle) is Control control)
			{
				var origin = setPos ? WindowSearch.GetControlReferenceWindow(item, target).ClientToScreen() : default;
#if LINUX
				// Wayland placement goes through the compositor; omitted axes stay in its screen coordinates.
				if (control is Form && WaylandOwnToplevels.IsSupported)
					_ = Platform.Window.TryMoveResize(item.Handle,
						new Rectangle(x == int.MinValue ? x : x + origin.X, y == int.MinValue ? y : y + origin.Y, width, height), setPos, setSize);
				else
#endif
				{
					if (setPos)
					{
						var parentOrigin = control.Parent?.ScreenOrigin(true) ?? PointF.Empty;
						var location = control is Forms.Window window ? window.Location : control.GetLocation();
						control.SetLocation(new Point(x == int.MinValue ? location.X : x + origin.X - Convert.ToInt32(parentOrigin.X),
							y == int.MinValue ? location.Y : y + origin.Y - Convert.ToInt32(parentOrigin.Y)));
					}

					if (setSize)
						control.Size = new Size(width == int.MinValue ? control.Size.Width : width, height == int.MinValue ? control.Size.Height : height);
				}
			}
			else
				_ = Platform.Window.TryMoveResize(item.Handle, new Rectangle(x, y, width, height), setPos, setSize);

			WindowInfoBase.DoControlDelay();
		}

		internal override long ControlGetStyle(object ctrl, object title, object text, object excludeTitle, object excludeText) => WindowSearch.SearchControl(ctrl, title, text, excludeTitle, excludeText) is WindowInfoBase item ? item.Style : 0L;

		internal override string ControlGetText(object ctrl, object title, object text, object excludeTitle, object excludeText)
		{
#if OSX
			if (TryResolveForeignMacControlTarget(ctrl, title, text, excludeTitle, excludeText, out var nativeWin, out var selector))
			{
				if (Keysharp.Internals.Window.MacOS.MacAccessibility.TryGetControlText(nativeWin, selector, out var axText))
					return axText;

				return (string)Errors.TargetErrorOccurred($"Could not get control {selector}", title, text, excludeTitle, excludeText, DefaultErrorString);
			}
#endif
			return OwnControl(ctrl, title, text, excludeTitle, excludeText)?.Text ?? "";
		}

#if OSX
		internal override void ControlSetText(string str, object ctrl, object title, object text, object excludeTitle, object excludeText)
		{
			if (TryResolveForeignMacControlTarget(ctrl, title, text, excludeTitle, excludeText, out var nativeWin, out var selector))
			{
				if (Keysharp.Internals.Window.MacOS.MacAccessibility.TrySetControlText(nativeWin, selector, str, out var foundControl))
				{
					WindowInfoBase.DoControlDelay();
					return;
				}

				if (!foundControl)
					_ = Errors.TargetErrorOccurred($"Could not get control {selector}", title, text, excludeTitle, excludeText);
				else
					_ = Errors.OSErrorOccurred("", $"macOS Accessibility could not set text on control '{selector}'.");
				return;
			}

			base.ControlSetText(str, ctrl, title, text, excludeTitle, excludeText);
		}
#endif

		internal override void ControlHideDropDown(object ctrl, object title, object text, object excludeTitle, object excludeText) =>
		DropdownHelper(false, ctrl, title, text, excludeTitle, excludeText);

		internal override void ControlSend(string str, object ctrl, object title, object text, object excludeTitle, object excludeText)
		{
			ControlSendHelper(str, ctrl, title, text, excludeTitle, excludeText, SendRawModes.NotRaw);
		}

		internal override void ControlSendText(string str, object ctrl, object title, object text, object excludeTitle, object excludeText)
		{
			ControlSendHelper(str, ctrl, title, text, excludeTitle, excludeText, SendRawModes.RawText);
		}

		internal override void ControlSetChecked(object val, object ctrl, object title, object text, object excludeTitle, object excludeText)
		{
#if OSX
			if (TryResolveForeignMacControlTarget(ctrl, title, text, excludeTitle, excludeText, out var nativeWin, out var selector))
			{
				var toggle = Conversions.ConvertOnOffToggle(val);
				if (Keysharp.Internals.Window.MacOS.MacAccessibility.TrySetControlChecked(nativeWin, selector, toggle, out var foundControl))
				{
					WindowInfoBase.DoControlDelay();
					return;
				}

				if (!foundControl)
					_ = Errors.TargetErrorOccurred($"Could not get control {selector}", title, text, excludeTitle, excludeText);
				return;
			}
#endif
			if (OwnControl(ctrl, title, text, excludeTitle, excludeText) is not Control control)
				return;

			var onoff = Conversions.ConvertOnOffToggle(val);

			if (control is CheckBox cb)
				cb.Checked = onoff == ToggleValueType.Toggle ? cb.Checked != true : onoff == ToggleValueType.On;
			else if (control is RadioButton rb)
				rb.Checked = onoff == ToggleValueType.Toggle ? !rb.Checked : onoff == ToggleValueType.On;
			else
				_ = WrongClass(control, "Button");

			WindowInfoBase.DoControlDelay();
		}

		internal override void ControlSetEnabled(object val, object ctrl, object title, object text, object excludeTitle, object excludeText)
		{
			if (OwnControl(ctrl, title, text, excludeTitle, excludeText) is not Control control)
				return;

			var onoff = Conversions.ConvertOnOffToggle(val);
			control.Enabled = onoff == ToggleValueType.Toggle ? !control.Enabled : onoff == ToggleValueType.On;
			WindowInfoBase.DoControlDelay();
		}

		/// <summary>
		/// On Linux the script's own windows take keys as GTK events; on macOS the script's own Edits take text.
		/// No way tells which X11 clients accept synthetic keys.
		/// </summary>
		private static void ControlSendHelper(string str, object ctrl, object title, object text, object excludeTitle, object excludeText, SendRawModes mode)
		{
#if OSX
			if (TryResolveForeignMacControlTarget(ctrl, title, text, excludeTitle, excludeText, out var nativeWin, out var selector))
			{
				if (!Keysharp.Internals.Window.MacOS.MacAccessibility.TryFocusControl(nativeWin, selector, out var foundControl, activateWindow: false))
				{
					if (!foundControl)
						_ = Errors.TargetErrorOccurred($"Could not get control {selector}", title, text, excludeTitle, excludeText);
					else
						_ = WindowHelper.WindowOperationUnsupported(mode == SendRawModes.RawText ? "ControlSendText" : "ControlSend");
					return;
				}

				Script.TheScript.Permissions.EnsureInputControl(operation: mode == SendRawModes.RawText ? "ControlSendText" : "ControlSend");
				Script.TheScript.HookThread.kbdMsSender.SendKeys(str, mode, SendModes.Event, (nint)(long)nativeWin.WindowNumber);
				return;
			}
#endif
			if (WindowSearch.SearchControl(ctrl, title, text, excludeTitle, excludeText) is not WindowInfoBase item)
				return;

			var own = Control.FromHandle(item.Handle);
#if LINUX
			if (own != null)
			{
				Script.TheScript.HookThread.kbdMsSender.SendKeys(str, mode, SendModes.Event, item.Handle);
				return;
			}

			_ = Errors.UnsupportedErrorOccurred(mode == SendRawModes.RawText
				? "ControlSendText cannot send text to another program's window on Linux."
				: "ControlSend cannot send keys to another program's window on Linux.");
#else
			if (own != null)
			{
				Script.TheScript.HookThread.kbdMsSender.SendKeys(str, mode, SendModes.Event, item.Handle);
				return;
			}

			Script.TheScript.Permissions.EnsureInputControl(operation: mode == SendRawModes.RawText ? "ControlSendText" : "ControlSend");
			Script.TheScript.HookThread.kbdMsSender.SendKeys(str, mode, SendModes.Event, item.Handle);
#endif
		}

		internal override void ControlShowDropDown(object ctrl, object title, object text, object excludeTitle, object excludeText) =>
		DropdownHelper(true, ctrl, title, text, excludeTitle, excludeText);

		//Lines are counted at the line breaks in the text, so a long line the control wraps is still one line, unlike in
		//a Windows edit control.
		internal override long EditGetCurrentCol(object ctrl, object title, object text, object excludeTitle, object excludeText)
		{
#if OSX
			if (TryResolveForeignMacControlTarget(ctrl, title, text, excludeTitle, excludeText, out var nativeWin, out var selector))
			{
				if (Keysharp.Internals.Window.MacOS.MacAccessibility.TryGetEditCurrentPos(nativeWin, selector, false, out var col, out var foundControl, out var unsupportedClass))
					return col;

				if (!foundControl)
					return (long)Errors.TargetErrorOccurred($"Could not get control {selector}", title, text, excludeTitle, excludeText, DefaultErrorLong);
				if (unsupportedClass)
					return (long)Errors.TargetErrorOccurred("The control is not an Edit", title, text, excludeTitle, excludeText, DefaultErrorLong);
				return 0L;
			}
#endif
			return GetEtoTextControl(ctrl, title, text, excludeTitle, excludeText) is TextControl edit
				? ComputeColFromOffset(edit.Text ?? "", edit.Selection.Start)
				: 0L;
		}

		internal override long EditGetCurrentLine(object ctrl, object title, object text, object excludeTitle, object excludeText)
		{
#if OSX
			if (TryResolveForeignMacControlTarget(ctrl, title, text, excludeTitle, excludeText, out var nativeWin, out var selector))
			{
				if (Keysharp.Internals.Window.MacOS.MacAccessibility.TryGetEditCurrentPos(nativeWin, selector, true, out var line, out var foundControl, out var unsupportedClass))
					return line;

				if (!foundControl)
					return (long)Errors.TargetErrorOccurred($"Could not get control {selector}", title, text, excludeTitle, excludeText, DefaultErrorLong);
				if (unsupportedClass)
					return (long)Errors.TargetErrorOccurred("The control is not an Edit", title, text, excludeTitle, excludeText, DefaultErrorLong);
				return 0L;
			}
#endif
			return GetEtoTextControl(ctrl, title, text, excludeTitle, excludeText) is TextControl edit
				? ComputeLineFromOffset(edit.Text ?? "", edit.Selection.Start)
				: 0L;
		}

		internal override string EditGetLine(int n, object ctrl, object title, object text, object excludeTitle, object excludeText)
		{
			if (n < 1)
				return (string)Errors.InvalidParameterErrorOccurred(1, "EditGetLine", n, DefaultErrorString);

#if OSX
			if (TryResolveForeignMacControlTarget(ctrl, title, text, excludeTitle, excludeText, out var nativeWin, out var selector))
			{
				if (Keysharp.Internals.Window.MacOS.MacAccessibility.TryGetEditLine(nativeWin, selector, n, out var lineText, out var totalLines, out var foundControl, out var unsupportedClass))
					return lineText;

				if (!foundControl)
					return (string)Errors.TargetErrorOccurred($"Could not get control {selector}", title, text, excludeTitle, excludeText, DefaultErrorString);
				if (unsupportedClass)
					return (string)Errors.TargetErrorOccurred("The control is not an Edit", title, text, excludeTitle, excludeText, DefaultErrorString);
				if (totalLines > 0)
					return (string)Errors.ValueErrorOccurred($"Requested line of {n} is greater than the number of lines ({totalLines}) in the text box in window with criteria: title: {title}, text: {text}, exclude title: {excludeTitle}, exclude text: {excludeText}", null, DefaultErrorString);
				return DefaultObject;
			}
#endif
			if (GetEtoTextControl(ctrl, title, text, excludeTitle, excludeText) is not TextControl edit)
				return DefaultObject;

			return TryGetTextLine(edit.Text ?? "", n, out var line, out var lineTotal)
				? line
				: (string)Errors.ValueErrorOccurred($"Requested line of {n} is greater than the number of lines ({lineTotal}) in the text box in window with criteria: title: {title}, text: {text}, exclude title: {excludeTitle}, exclude text: {excludeText}", null, DefaultErrorString);
		}

		internal override long EditGetLineCount(object ctrl, object title, object text, object excludeTitle, object excludeText)
		{
#if OSX
			if (TryResolveForeignMacControlTarget(ctrl, title, text, excludeTitle, excludeText, out var nativeWin, out var selector))
			{
				if (Keysharp.Internals.Window.MacOS.MacAccessibility.TryGetEditLineCount(nativeWin, selector, out var lineCount, out var foundControl, out var unsupportedClass))
					return lineCount;

				if (!foundControl)
					return (long)Errors.TargetErrorOccurred($"Could not get control {selector}", title, text, excludeTitle, excludeText, DefaultErrorLong);
				if (unsupportedClass)
					return (long)Errors.TargetErrorOccurred("The control is not an Edit", title, text, excludeTitle, excludeText, DefaultErrorLong);
				return 0L;
			}
#endif
			return GetEtoTextControl(ctrl, title, text, excludeTitle, excludeText) is TextControl edit
				? CountTextLines(edit.Text ?? "")
				: 0L;
		}

		internal override string EditGetSelectedText(object ctrl, object title, object text, object excludeTitle, object excludeText)
		{
#if OSX
			if (TryResolveForeignMacControlTarget(ctrl, title, text, excludeTitle, excludeText, out var nativeWin, out var selector))
			{
				if (Keysharp.Internals.Window.MacOS.MacAccessibility.TryGetEditSelectedText(nativeWin, selector, out var selectedText, out var foundControl, out var unsupportedClass))
					return selectedText;

				if (!foundControl)
					return (string)Errors.TargetErrorOccurred($"Could not get control {selector}", title, text, excludeTitle, excludeText, DefaultErrorString);
				if (unsupportedClass)
					return (string)Errors.TargetErrorOccurred("The control is not an Edit", title, text, excludeTitle, excludeText, DefaultErrorString);
				return DefaultObject;
			}
#endif
			if (GetEtoTextControl(ctrl, title, text, excludeTitle, excludeText) is not TextControl edit)
				return DefaultObject;

			var selection = edit.Selection;
			return selection.Length() > 0 ? (edit.Text ?? "").Substring(selection.Start, selection.Length()) : "";
		}

		internal override void EditPaste(string str, object ctrl, object title, object text, object excludeTitle, object excludeText)
		{
#if OSX
			if (TryResolveForeignMacControlTarget(ctrl, title, text, excludeTitle, excludeText, out var nativeWin, out var selector))
			{
				if (Keysharp.Internals.Window.MacOS.MacAccessibility.TryPasteEditText(nativeWin, selector, str, out var foundControl, out var unsupportedClass))
				{
					WindowInfoBase.DoControlDelay();
					return;
				}

				if (!foundControl)
					_ = Errors.TargetErrorOccurred($"Could not get control {selector}", title, text, excludeTitle, excludeText);
				else if (unsupportedClass)
					_ = Errors.TargetErrorOccurred("The control is not an Edit", title, text, excludeTitle, excludeText);
				else
					_ = Errors.OSErrorOccurred("", $"macOS Accessibility could not paste into edit control '{selector}'.");
				return;
			}
#endif
			if (GetEtoTextControl(ctrl, title, text, excludeTitle, excludeText) is not TextControl edit)
				return;

			ReplaceSelection(edit, str);
			WindowInfoBase.DoControlDelay();
		}

		/// <summary>As EM_REPLACESEL, and as typing: the text replaces the selection and the caret follows it.</summary>
		private static void ReplaceSelection(TextControl edit, string text)
		{
			var selection = edit.Selection;
			edit.ReplaceText(selection.Start, selection.Length(), text);
			edit.CaretIndex = selection.Start + text.Length;
		}

		/// <summary>The Edit or RichEdit control the criteria name, or null after raising the error when they name none.</summary>
		private static TextControl GetEtoTextControl(object ctrl, object title, object text, object excludeTitle, object excludeText)
		{
			if (OwnControl(ctrl, title, text, excludeTitle, excludeText) is not Control control)
				return null;

			if (control is TextBox or TextArea or PasswordBox)
				return (TextControl)control;

			_ = Errors.TargetErrorOccurred("The control is not an Edit", title, text, excludeTitle, excludeText);
			return null;
		}

		internal override object ListViewGetContent(string options, object ctrl, object title, object text, object excludeTitle, object excludeText)
		{
			object ret = null;

			if (OwnControl(ctrl, title, text, excludeTitle, excludeText) is Control control)
			{
				var focused = false;
				var count = false;
				var sel = false;
				var countcol = false;
				var col = int.MinValue;
				var opts = Options.ParseOptions(options);

				foreach (var opt in opts)
				{
					if (string.Compare(opt, "focused", true) == 0) { focused = true; }
					else if (string.Compare(opt, "count", true) == 0) { count = true; }
					else if (string.Compare(opt, "selected", true) == 0) { sel = true; }
					else if (string.Compare(opt, "col", true) == 0) { countcol = true; }
					else if (Options.TryParse(opt, "col", ref col)) { col--; }
				}

				if (control is KeysharpListView lv)
				{
					//As in AutoHotkey, Focused takes precedence over Selected.
					if (count && focused)
						ret = lv.FocusedRow + 1L;
					else if (count && sel)
						ret = (long)lv.SelectedIndices.Count;
					else if (count && countcol)
						ret = (long)lv.Columns.Count;
					else if (count)
						ret = (long)lv.Items.Count;
					else
					{
						if (col != int.MinValue && (col < 0 || col >= lv.Columns.Count))
							return Errors.ValueErrorOccurred($"Column {col + 1} is outside the list view column count of {lv.Columns.Count}.");

						IEnumerable<int> rows = focused ? (lv.FocusedRow is var focusedRow and >= 0 ? [focusedRow] : []) : sel ? lv.SelectedIndices : Enumerable.Range(0, lv.Items.Count);
						var sb = new StringBuilder(1024);
						var firstRow = true;

						//A linefeed between rows, none after the last, and a tab between the cells of a row.
						foreach (var row in rows)
						{
							if (!firstRow)
								_ = sb.Append('\n');

							firstRow = false;
							var cells = lv.Items[row];

							if (col >= 0)
								_ = sb.Append(GetCellText(cells, col));
							else
								for (var c = 0; c < lv.Columns.Count; c++)
									_ = (c > 0 ? sb.Append('\t') : sb).Append(GetCellText(cells, c));
						}

						ret = sb.ToString();
					}
				}
				else
					ret = WrongClass(control, "SysListView32");
			}

			return ret;
		}

		internal override void MenuSelect(object title, object text, object menu, object sub1, object sub2, object sub3, object sub4, object sub5, object sub6, object excludeTitle, object excludeText)
		{
			if (WindowSearch.SearchWindow(title, text, excludeTitle, excludeText, true) is WindowInfoBase win)
			{
				if (Control.FromHandle(win.Handle) is Form form)
				{
					if (form.MainMenuStrip is MenuStrip strip)
					{
						if (!TryGetMenuItem(strip, out var item, menu, sub1, sub2, sub3, sub4, sub5, sub6))
							return;

						if (item != null)
							item.PerformClick();
						else
							_ = Errors.ValueErrorOccurred($"Could not find menu.", $"{title}, {text}, {menu}, {sub1}, {sub2}, {sub3}, {sub4}, {sub5}, {sub6}, {excludeTitle}, {excludeText}");
					}
				}
#if OSX
				else if (Keysharp.Internals.Window.MacOS.MacNativeWindows.TryGetWindowInfo(win.Handle, out var nativeWin)
					&& nativeWin.OwnerPid != Environment.ProcessId)
				{
					if (!TryCollectMenuPath([menu, sub1, sub2, sub3, sub4, sub5, sub6], out var steps))
						return;

					if (steps.Count == 0 || string.IsNullOrEmpty(steps[0]))
					{
						_ = Errors.ValueErrorOccurred($"Could not find menu.", $"{title}, {text}, {menu}, {sub1}, {sub2}, {sub3}, {sub4}, {sub5}, {sub6}, {excludeTitle}, {excludeText}");
						return;
					}

					if (!Keysharp.Internals.Window.MacOS.MacAccessibility.TrySelectMenuItem(nativeWin, steps, out var failure))
						_ = Errors.ValueErrorOccurred(failure ?? "Could not find menu.", $"{title}, {text}, {menu}, {sub1}, {sub2}, {sub3}, {sub4}, {sub5}, {sub6}, {excludeTitle}, {excludeText}");
				}
#endif
			}
		}

		internal override void PostMessage(uint msg, nint wparam, nint lparam, object ctrl, object title, object text, object excludeTitle, object excludeText)
		{
			_ = TryDispatchWindowMessage(msg, wparam, lparam, ctrl, title, text, excludeTitle, excludeText, post: true, out _);
		}

		internal override long SendMessage(uint msg, object wparam, object lparam, object ctrl, object title, object text, object excludeTitle, object excludeText, int timeout)
		{
			if (!wparam.CoerceInt(out var wp) || !lparam.CoerceInt(out var lp))
				return 0L;

			return TryDispatchWindowMessage(msg, wp, lp, ctrl, title, text, excludeTitle, excludeText, post: false, out var result) ? result : 0L;
		}

		private static bool TryDispatchWindowMessage(uint msg, nint wparam, nint lparam, object ctrl, object title, object text, object excludeTitle, object excludeText, bool post, out long result)
		{
			result = 0L;
			if (WindowSearch.SearchControl(ctrl, title, text, excludeTitle, excludeText, false) is not WindowInfoBase target)
				return false;

			if (target is not ControlInfo item)
			{
				if (msg == (uint)WindowsAPI.WM_CLOSE)
				{
					if (post)
						Application.Instance.AsyncInvoke(() => _ = Platform.Window.TryClose(target.Handle));
					else
						result = Platform.Window.TryClose(target.Handle) ? 1L : 0L;
					return true;
				}

				return false;
			}

			var handler = CreateWindowMessageHandler(item.Control, msg, wparam, lparam);

			if (handler == null)
				return false;

			if (post)
#if LINUX
				//AsyncInvoke (GtkSharp's Application.Invoke) runs at a higher priority than GTK's
				//layout finalization, so it can fire before freshly-changed text is laid out (e.g. a
				//scroll-to-end would land one line short). A default-priority idle runs after layout.
				_ = GLib.Idle.Add(() => { _ = handler(); return false; });
#else
				Application.Instance.AsyncInvoke(() => _ = handler());
#endif
			else
				result = InvokeWindowMessageHandler(handler);

			return true;
		}

		internal static Func<long> CreateWindowMessageHandler(Control control, uint msg, nint wparam, nint lparam) =>
			msg switch
			{
				(uint)WindowsAPI.WM_CLOSE => control is Form form ? () => { form.Close(); return 0L; } : null,
				(uint)WindowsAPI.WM_GETTEXTLENGTH => () => control.Text?.Length ?? 0L,
				(uint)WindowsAPI.WM_VSCROLL => WrapVoidAction(CreateTextAreaScrollAction(control, wparam)),
				(uint)WindowsAPI.EM_SCROLLCARET => WrapVoidAction(CreateTextAreaScrollCaretAction(control)),
				(uint)WindowsAPI.EM_SETSEL => WrapVoidAction(CreateTextControlSetSelAction(control, wparam, lparam)),
				(uint)WindowsAPI.EM_GETLINECOUNT => control is TextControl edit ? () => CountTextLines(edit.Text) : null,
				(uint)WindowsAPI.EM_SETREADONLY => CreateSetReadOnlyHandler(control, wparam != 0),
				(uint)WindowsAPI.BM_GETCHECK => () => control switch
				{
					CheckBox cb => cb.Checked == true ? (long)WindowsAPI.BST_CHECKED : (long)WindowsAPI.BST_UNCHECKED,
					RadioButton rb => rb.Checked ? (long)WindowsAPI.BST_CHECKED : (long)WindowsAPI.BST_UNCHECKED,
					_ => 0L
				},
				(uint)WindowsAPI.BM_SETCHECK => control switch
				{
					CheckBox cb => () => { cb.Checked = wparam.ToInt64() == WindowsAPI.BST_CHECKED; return 0L; },
					RadioButton rb => () => { rb.Checked = wparam.ToInt64() == WindowsAPI.BST_CHECKED; return 0L; },
					_ => null
				},
				(uint)WindowsAPI.BM_CLICK => control is Button btn ? () => { if (btn.Enabled) btn.PerformClick(); return 0L; } : null,
				(uint)WindowsAPI.CB_GETCOUNT => control is KeysharpComboBox cb ? () => cb.Items.Count : null,
				(uint)WindowsAPI.CB_GETCURSEL => control is KeysharpComboBox cb ? () => cb.SelectedIndex : null,
				(uint)WindowsAPI.CB_SETCURSEL => control is KeysharpComboBox cb ? () => SetListControlSelection(cb, wparam, WindowsAPI.CB_ERR) : null,
				(uint)WindowsAPI.CB_RESETCONTENT => control is KeysharpComboBox cb ? () => { cb.Items.Clear(); return 0L; } : null,
				(uint)WindowsAPI.LB_GETCOUNT => control is KeysharpListBox lb ? () => lb.Items.Count : null,
				(uint)WindowsAPI.LB_GETCURSEL => control is KeysharpListBox lb ? () => lb.SelectedIndex : null,
				(uint)WindowsAPI.LB_SETCURSEL => control is KeysharpListBox lb ? () => SetListControlSelection(lb, wparam, WindowsAPI.LB_ERR) : null,
				(uint)WindowsAPI.LB_RESETCONTENT => control is KeysharpListBox lb ? () => { lb.Items.Clear(); return 0L; } : null,
				_ => null
			};

		private static Func<long> WrapVoidAction(Action action) =>
			action == null ? null : () => { action(); return 1L; };

		private static long SetListControlSelection(ListControl list, nint wparam, long errorResult)
		{
			var index = (int)wparam.ToInt64();
			if (index < -1 || index >= list.Items.Count)
				return errorResult;

			list.SelectedIndex = index;
			return index;
		}

		private static Func<long> CreateSetReadOnlyHandler(Control control, bool readOnly) =>
			control switch
			{
				TextBox box => () => { box.ReadOnly = readOnly; return 1L; },
				TextArea area => () => { area.ReadOnly = readOnly; return 1L; },
				PasswordBox pw => () => { pw.ReadOnly = readOnly; return 1L; },
				_ => null
			};

		internal static (int From, int To) ComputeEditSelectionBounds(int textLength, int caretIndex, int start, int end)
		{
			var clampedLen = Math.Max(0, textLength);

			if (start == -1)
			{
				var caret = Math.Clamp(caretIndex, 0, clampedLen);
				return (caret, caret);
			}

			var from = Math.Clamp(start, 0, clampedLen);
			var to = end == -1 ? clampedLen : Math.Clamp(end, 0, clampedLen);

			if (to < from)
				(from, to) = (to, from);

			return (from, to);
		}

		//EM_SETSEL(start, end): select a character range. The two documented special cases are honoured
		//because scripts rely on them: start == -1 deselects and parks the caret at the current end, and
		//end == -1 selects to the end of the text.
		//Eto's Range<int> is INCLUSIVE (see ScrollTextAreaToOffset), so an exclusive [start, end)
		//becomes Range(start, end - 1), and an empty selection becomes Range(caret, caret - 1).
		private static Action CreateTextControlSetSelAction(Control control, nint wparam, nint lparam)
		{
			var start = (int)wparam.ToInt64();
			var end = (int)lparam.ToInt64();

			if (control is TextArea area)
			{
				return () =>
				{
					var (from, to) = ComputeEditSelectionBounds(area.Text?.Length ?? 0, area.CaretIndex, start, end);
					area.Selection = new Range<int>(from, to - 1);
				};
			}

			if (control is TextBox box)
			{
				return () =>
				{
					var (from, to) = ComputeEditSelectionBounds(box.Text?.Length ?? 0, box.CaretIndex, start, end);
					box.Selection = new Range<int>(from, to - 1);
				};
			}

			return null;
		}

		private static Action CreateTextAreaScrollAction(Control control, nint wparam)
		{
			if (control is not TextArea area)
				return null;

			var cmd = unchecked((int)(wparam.ToInt64() & 0xFFFF));//WM_VSCROLL packs the scroll command in the low word.

			return cmd switch
			{
				WindowsAPI.SB_TOP => area.ScrollToStart,
				WindowsAPI.SB_BOTTOM => () => ScrollTextAreaToEnd(area),
				_ => null
			};
		}

		private static Action CreateTextAreaScrollCaretAction(Control control) =>
			control is TextArea area ? () => ScrollTextAreaToOffset(area, area.CaretIndex) : null;

		private static long InvokeWindowMessageHandler(Func<long> handler)
		{
			var app = Application.Instance;

			if (app == null || app.IsUIThread)
				return handler();

			return app.Invoke(handler);
		}

		private static void ScrollTextAreaToOffset(TextArea area, int offset)
		{
			//Eto's TextArea.ScrollTo scrolls to offset (range.Start + range.Length()), and Range<int>.Length()
			//is inclusive (End - Start + 1). End = Start - 1 targets exactly Start, and maps to NSRange(Start, 0).
			area.ScrollTo(new Range<int>(offset, offset - 1));
		}

		private static void ScrollTextAreaToEnd(TextArea area)
		{
			area.ScrollToEnd();
		}

		private static void DropdownHelper(bool val, object ctrl, object title, object text, object excludeTitle, object excludeText)
		{
#if OSX
			if (TryResolveForeignMacControlTarget(ctrl, title, text, excludeTitle, excludeText, out var nativeWin, out var selector))
			{
				if (Keysharp.Internals.Window.MacOS.MacAccessibility.TrySetControlDropDownState(
					nativeWin,
					selector,
					val,
					out var foundControl,
					out var unsupportedClass))
				{
					WindowInfoBase.DoControlDelay();
					return;
				}

				if (!foundControl)
					_ = Errors.TargetErrorOccurred($"Could not get control {selector}", title, text, excludeTitle, excludeText);
				else if (unsupportedClass)
					_ = Errors.TargetErrorOccurred($"Control {selector} did not match Combo", title, text, excludeTitle, excludeText);
				else
					_ = WindowHelper.WindowOperationUnsupported(val ? "ControlShowDropDown" : "ControlHideDropDown");
				return;
			}
#endif
			if (OwnControl(ctrl, title, text, excludeTitle, excludeText) is not Control control)
				return;

#if LINUX
			if (control.ControlObject is Gtk.ComboBox combo)
			{
				if (val)
					combo.Popup();
				else
					combo.Popdown();

				WindowInfoBase.DoControlDelay();
			}
#else
			if (control is ComboBox)
				_ = WindowHelper.WindowOperationUnsupported(val ? "ControlShowDropDown" : "ControlHideDropDown");
#endif
			else
				_ = WrongClass(control, "Combo");
		}
	}
}

#endif
