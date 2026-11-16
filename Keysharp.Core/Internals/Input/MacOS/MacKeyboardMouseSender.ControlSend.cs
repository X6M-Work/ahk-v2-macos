#if OSX
using Keysharp.Builtins;
using Keysharp.Internals.Input.Hooks.Unix;
using Keysharp.Internals.Input.Keyboard;
using Keysharp.Internals.Window.Unix;
using static Keysharp.Internals.Input.Keyboard.KeyboardMouseSender;
using static Keysharp.Internals.Input.Keyboard.KeyboardUtils;
using static Keysharp.Internals.Input.Keyboard.VirtualKeys;

namespace Keysharp.Internals.Input.MacOS
{
	internal partial class MacKeyboardMouseSender
	{
		private sealed class OwnEditState
		{
			internal bool Overwrite;
			internal Eto.Forms.Range<int>? PasswordSelection;
		}

		private static readonly ConditionalWeakTable<TextControl, OwnEditState> ownEditStates = new();
		private uint targetSentModifiersLR;
		private uint targetHeldModifiersLR;
		private char targetHighSurrogate;

		protected override bool TargetWindowSendUsesGlobalInput => false;

		private void ResetTargetedSendState()
		{
			targetSentModifiersLR = 0;
			targetHeldModifiersLR = 0;
			targetHighSurrogate = '\0';
		}

		// Targeted ControlSend keeps its modifier state local to the target instead of changing global HID flags.
		internal override void SetModifierLRState(uint modifiersLRnew, uint modifiersLRnow, nint targetWindow,
			bool disguiseDownWinAlt, bool disguiseUpWinAlt, long extraInfo = KeyIgnoreAllExceptModifier)
		{
			if (targetWindow != 0)
			{
				targetSentModifiersLR = modifiersLRnew;
				return;
			}

			// Seed the native event stream from the sender's synchronous prediction. Each modifier event posted
			// by base updates this field before the next event is created, independently of WindowServer timing.
			keyboardState.SetModifiers(modifiersLRnow);
			base.SetModifierLRState(modifiersLRnew, modifiersLRnow, targetWindow,
				disguiseDownWinAlt, disguiseUpWinAlt, extraInfo);
		}

		internal override void SendKeyEventToTargetWindow(KeyEventTypes eventType, uint vk, uint sc = 0u,
			nint targetWindow = default, bool doKeyDelay = false, long extraInfo = KeyIgnoreAllExceptModifier)
		{
			if (targetWindow == 0)
				return;

			if (vk == 0 && sc != 0)
				_ = KeyCodes.TryMapMacCodeToVk(sc, out vk);

			bool? isNeutral = null;
			var modifierLR = script.HookThread.KeyToModifiersLR(vk, sc, ref isNeutral);
			var own = Control.FromHandle(targetWindow);

			if (own != null)
			{
				if (eventType != KeyEventTypes.KeyUp)
				{
					var modifiers = targetSentModifiersLR | targetHeldModifiersLR | modifierLR;
					PostOwnTargetKey(own, down: true, vk, modifiers);
					targetHeldModifiersLR |= modifierLR;
				}

				if (doKeyDelay && eventType == KeyEventTypes.KeyDownAndUp)
					DoKeyDelay(ThreadAccessors.A_KeyDuration);

				if (eventType != KeyEventTypes.KeyDown)
				{
					targetHeldModifiersLR &= ~modifierLR;
					var modifiers = targetSentModifiersLR | targetHeldModifiersLR;
					PostOwnTargetKey(own, down: false, vk, modifiers);
				}

				return;
			}

			if (!MacNativeWindows.TryGetWindowInfo(targetWindow, out var nativeWin) || nativeWin.OwnerPid <= 0)
				return;

			var pid = (int)nativeWin.OwnerPid;
			var capsLock = CurrentCapsLockState();

			if (eventType != KeyEventTypes.KeyUp)
			{
				var modifiers = targetSentModifiersLR | targetHeldModifiersLR | modifierLR;
				_ = MacNativeInput.PostKeyboardToPid(pid, vk, true, extraInfo, modifiers, capsLockOn: capsLock);
				targetHeldModifiersLR |= modifierLR;
			}

			if (doKeyDelay && eventType == KeyEventTypes.KeyDownAndUp)
				DoKeyDelay(ThreadAccessors.A_KeyDuration);

			if (eventType != KeyEventTypes.KeyDown)
			{
				targetHeldModifiersLR &= ~modifierLR;
				var modifiers = targetSentModifiersLR | targetHeldModifiersLR;
				_ = MacNativeInput.PostKeyboardToPid(pid, vk, false, extraInfo, modifiers, capsLockOn: capsLock);
			}
		}

		internal override void SendCharToTargetWindow(char ch, nint targetWindow)
		{
			if (targetWindow == 0)
				return;

			if (char.IsHighSurrogate(ch))
			{
				targetHighSurrogate = ch;
				return;
			}

			var high = targetHighSurrogate;
			targetHighSurrogate = '\0';

			if (char.IsLowSurrogate(ch) && high == '\0')
				return;

			var text = char.IsLowSurrogate(ch)
				? new string([high, ch])
				: ch.ToString();

			if (Control.FromHandle(targetWindow) is Control own)
			{
				script.PostToUIThread(() => DeliverOwnTargetText(own, text));
				return;
			}

			if (MacNativeWindows.TryGetWindowInfo(targetWindow, out var nativeWin) && nativeWin.OwnerPid > 0)
				MacNativeInput.PostUnicodeTextToPid((int)nativeWin.OwnerPid, text, KeyIgnoreLevel(ThreadAccessors.A_SendLevel));
		}

		internal static Forms.Keys BuildEtoKeyData(uint vk, uint modifiersLR)
		{
			var key = EtoMessageSource.FromVirtualKey(vk);
			if (key == Forms.Keys.None)
				return Forms.Keys.None;

			if ((modifiersLR & (MOD_LSHIFT | MOD_RSHIFT)) != 0)
				key |= Forms.Keys.Shift;
			if ((modifiersLR & (MOD_LCONTROL | MOD_RCONTROL)) != 0)
				key |= Forms.Keys.Control;
			if ((modifiersLR & (MOD_LALT | MOD_RALT)) != 0)
				key |= Forms.Keys.Alt;
			if ((modifiersLR & (MOD_LWIN | MOD_RWIN)) != 0)
				key |= Forms.Keys.Application;

			return key;
		}

		internal static char? TryResolveKeyChar(uint vk, uint modifiersLR)
		{
			if ((modifiersLR & (MOD_LCONTROL | MOD_RCONTROL | MOD_LALT | MOD_RALT | MOD_LWIN | MOD_RWIN)) != 0)
				return null;

			var shift = (modifiersLR & (MOD_LSHIFT | MOD_RSHIFT)) != 0;
			if (KeyCodes.TryMapKeystrokeToRune(vk, shift, false, out var rune) && rune.Utf16SequenceLength == 1)
				return (char)rune.Value;

			if (vk is >= 'A' and <= 'Z')
				return shift ? (char)vk : char.ToLowerInvariant((char)vk);

			if (vk is >= '0' and <= '9' && !shift)
				return (char)vk;

			return vk == VK_SPACE ? ' ' : null;
		}

		private void PostOwnTargetKey(Control owner, bool down, uint vk, uint modifiersLR)
		{
			var etoKey = BuildEtoKeyData(vk, modifiersLR);
			var keyChar = TryResolveKeyChar(vk, modifiersLR);
			script.PostToUIThread(() => DeliverOwnTargetKey(owner, down, vk, etoKey, modifiersLR, keyChar));
		}

		private static Control ResolveOwnTargetControl(Control owner)
			=> owner is Forms.Form form ? (form.ActiveControl ?? owner) : owner;

		private static bool RaiseEtoKeyEvent(Control control, bool down, Forms.Keys etoKey, char? keyChar, out KeyEventArgs args)
		{
			var type = down ? KeyEventType.KeyDown : KeyEventType.KeyUp;
			args = keyChar.HasValue ? new KeyEventArgs(etoKey, type, keyChar.Value) : new KeyEventArgs(etoKey, type);

			if (control is Eto.ICallbackSource { Callback: Control.ICallback callback })
			{
				if (down)
					callback.OnKeyDown(control, args);
				else
					callback.OnKeyUp(control, args);
			}

			return args.Handled;
		}

		private static void DeliverOwnTargetKey(Control owner, bool down, uint vk, Forms.Keys etoKey, uint modifiersLR, char? keyChar)
		{
			if (owner.IsDisposed)
				return;

			var target = ResolveOwnTargetControl(owner);
			if (target.IsDisposed)
				return;

			if (etoKey != Forms.Keys.None)
			{
				if (RaiseEtoKeyEvent(target, down, etoKey, keyChar, out var args))
					return;

				if (target != owner && owner is Forms.Window && RaiseEtoKeyEvent(owner, down, etoKey, keyChar, out args))
					return;
			}

			if (!down)
				return;

			if (target is TextControl edit)
			{
				HandleOwnTextControlKey(edit, vk, modifiersLR, keyChar);
				return;
			}

			if (target is Button btn && (vk == VK_RETURN || vk == VK_SPACE) && btn.Enabled)
				btn.PerformClick();
			else if (target is CheckBox cb && vk == VK_SPACE && cb.Enabled)
				cb.Checked = cb.Checked != true;
		}

		private static void DeliverOwnTargetText(Control owner, string text)
		{
			if (owner.IsDisposed || string.IsNullOrEmpty(text))
				return;

			var target = ResolveOwnTargetControl(owner);
			if (target.IsDisposed)
				return;

			if (target is TextControl edit)
			{
				DeliverTextToTextControl(edit, text);
				return;
			}

			if (target is Eto.ICallbackSource { Callback: Control.ICallback callback })
				callback.OnTextInput(target, new TextInputEventArgs(text));
		}

		private static void HandleOwnTextControlKey(TextControl edit, uint vk, uint modifiersLR, char? keyChar)
		{
			var hasNonShiftModifier = (modifiersLR & (MOD_LCONTROL | MOD_RCONTROL | MOD_LALT | MOD_RALT | MOD_LWIN | MOD_RWIN)) != 0;
			var shift = (modifiersLR & (MOD_LSHIFT | MOD_RSHIFT)) != 0;

			if (vk == 'A'
				&& (modifiersLR & (MOD_LCONTROL | MOD_RCONTROL | MOD_LWIN | MOD_RWIN)) != 0
				&& (modifiersLR & (MOD_LALT | MOD_RALT | MOD_LSHIFT | MOD_RSHIFT)) == 0)
			{
				var length = (edit.Text ?? "").Length;
				SetOwnSelection(edit, Eto.Forms.Range.FromLength(0, length));
				return;
			}

			switch (vk)
			{
				case VK_LEFT:
					MoveOwnCaret(edit, -1, shift, toBoundary: false);
					return;
				case VK_RIGHT:
					MoveOwnCaret(edit, 1, shift, toBoundary: false);
					return;
				case VK_HOME:
					MoveOwnCaret(edit, -1, shift, toBoundary: true);
					return;
				case VK_END:
					MoveOwnCaret(edit, 1, shift, toBoundary: true);
					return;
				case VK_INSERT:
					if (!hasNonShiftModifier && !shift)
					{
						var state = ownEditStates.GetOrCreateValue(edit);
						state.Overwrite = !state.Overwrite;
					}
					return;
				case VK_BACK:
					if (!hasNonShiftModifier)
						DeleteInTextControl(edit, forward: false);
					return;
				case VK_DELETE:
					if (!hasNonShiftModifier)
						DeleteInTextControl(edit, forward: true);
					return;
				case VK_RETURN:
					if (edit is TextArea area)
					{
						if (area.AcceptsReturn)
							DeliverTextToTextControl(edit, "\n");
					}
					else if (edit.ParentWindow is Forms.Form form && form.DefaultButton is Button def && def.Enabled)
						def.PerformClick();
					return;
				case VK_TAB:
					if (edit is TextArea tabArea && tabArea.AcceptsTab)
						DeliverTextToTextControl(edit, "\t");
					return;
			}

			if (keyChar.HasValue && !char.IsControl(keyChar.Value))
				DeliverTextToTextControl(edit, keyChar.Value.ToString());
		}

		private static bool IsTextControlReadOnly(TextControl edit) => edit switch
		{
			TextBox box => box.ReadOnly,
			TextArea area => area.ReadOnly,
			PasswordBox pw => pw.ReadOnly,
			_ => false
		};

		private static Eto.Forms.Range<int> GetOwnSelection(TextControl edit)
		{
			var len = (edit.Text ?? "").Length;
			if (edit is PasswordBox)
			{
				var state = ownEditStates.GetOrCreateValue(edit);
				var sel = state.PasswordSelection ?? Eto.Forms.Range.FromLength(len, 0);
				var start = Math.Clamp(sel.Start, 0, len);
				var end = Math.Clamp(sel.End, start - 1, len - 1);
				return new Eto.Forms.Range<int>(start, end);
			}

			var raw = edit.Selection;
			var clampedStart = Math.Clamp(raw.Start, 0, len);
			var clampedEnd = Math.Clamp(raw.End, clampedStart - 1, len - 1);
			return new Eto.Forms.Range<int>(clampedStart, clampedEnd);
		}

		private static void SetOwnSelection(TextControl edit, Eto.Forms.Range<int> selection)
		{
			var len = (edit.Text ?? "").Length;
			var start = Math.Clamp(selection.Start, 0, len);
			var end = Math.Clamp(selection.End, start - 1, len - 1);
			var clamped = new Eto.Forms.Range<int>(start, end);

			if (edit is PasswordBox)
			{
				ownEditStates.GetOrCreateValue(edit).PasswordSelection = clamped;
				return;
			}

			edit.Selection = clamped;
		}

		private static void SetOwnCaret(TextControl edit, int index)
		{
			var len = (edit.Text ?? "").Length;
			var clamped = Math.Clamp(index, 0, len);

			if (edit is PasswordBox)
			{
				ownEditStates.GetOrCreateValue(edit).PasswordSelection = Eto.Forms.Range.FromLength(clamped, 0);
				return;
			}

			edit.CaretIndex = clamped;
		}

		private static void MoveOwnCaret(TextControl edit, int direction, bool extendSelection, bool toBoundary)
		{
			var text = edit.Text ?? "";
			var sel = GetOwnSelection(edit);
			int target;

			if (!toBoundary)
			{
				if (!extendSelection && sel.Length() > 0)
					target = direction < 0 ? sel.Start : sel.End + 1;
				else
				{
					var pos = direction < 0 ? sel.Start : sel.End + 1;
					target = direction < 0
						? PreviousTextElementStart(text, pos)
						: pos < text.Length ? pos + StringInfo.GetNextTextElementLength(text, pos) : text.Length;
				}
			}
			else if (edit is TextArea)
			{
				var pos = direction < 0 ? sel.Start : sel.End + 1;
				if (direction < 0)
				{
					var nl = pos > 0 ? text.LastIndexOf('\n', pos - 1) : -1;
					target = nl >= 0 ? nl + 1 : 0;
				}
				else
				{
					var nl = pos < text.Length ? text.IndexOf('\n', pos) : -1;
					target = nl >= 0 ? nl : text.Length;
				}
			}
			else
			{
				target = direction < 0 ? 0 : text.Length;
			}

			if (!extendSelection)
			{
				SetOwnCaret(edit, target);
				return;
			}

			var anchor = direction < 0 ? sel.End + 1 : sel.Start;
			var start = Math.Min(anchor, target);
			var end = Math.Max(anchor, target);
			SetOwnSelection(edit, Eto.Forms.Range.FromLength(start, end - start));
		}

		private static int PreviousTextElementStart(string text, int index)
		{
			if (index <= 0 || text.Length == 0)
				return 0;

			var clamped = Math.Min(index, text.Length);
			var enumerator = StringInfo.GetTextElementEnumerator(text);
			var lastStart = 0;

			while (enumerator.MoveNext())
			{
				var pos = enumerator.ElementIndex;
				if (pos >= clamped)
					break;

				lastStart = pos;
			}

			return lastStart;
		}

		private static void DeleteInTextControl(TextControl edit, bool forward)
		{
			if (IsTextControlReadOnly(edit))
				return;

			var text = edit.Text ?? "";
			var sel = GetOwnSelection(edit);
			int start;
			int length;

			if (sel.Length() > 0)
			{
				start = sel.Start;
				length = sel.Length();
			}
			else if (forward)
			{
				if (sel.Start >= text.Length)
					return;

				start = sel.Start;
				length = StringInfo.GetNextTextElementLength(text, start);
			}
			else
			{
				if (sel.Start <= 0)
					return;

				start = PreviousTextElementStart(text, sel.Start);
				length = sel.Start - start;
			}

			if (edit is TextBox box && edit is Eto.ICallbackSource { Callback: TextBox.ICallback tbCb })
			{
				var changing = new TextChangingEventArgs(string.Empty, Eto.Forms.Range.FromLength(start, length), TextChangeSource.Keyboard);
				tbCb.OnTextChanging(box, changing);
				if (changing.Cancel)
					return;
			}

			edit.ReplaceText(start, length, string.Empty);
			SetOwnCaret(edit, start);
		}

		private static void DeliverTextToTextControl(TextControl edit, string text)
		{
			if (IsTextControlReadOnly(edit) || string.IsNullOrEmpty(text))
				return;

			var current = edit.Text ?? "";
			var sel = GetOwnSelection(edit);
			var start = sel.Start;
			var length = sel.Length();

			if (length == 0
				&& ownEditStates.TryGetValue(edit, out var state)
				&& state.Overwrite
				&& start < current.Length
				&& text != "\n" && text != "\t")
			{
				length = StringInfo.GetNextTextElementLength(current, start);
			}

			if (edit is TextBox box && edit is Eto.ICallbackSource { Callback: TextBox.ICallback tbCb })
			{
				var changing = new TextChangingEventArgs(text, Eto.Forms.Range.FromLength(start, length), TextChangeSource.Keyboard);
				tbCb.OnTextChanging(box, changing);
				if (changing.Cancel)
					return;
			}

			if (edit is Eto.ICallbackSource { Callback: Control.ICallback ctrlCb })
			{
				var inputArgs = new TextInputEventArgs(text);
				ctrlCb.OnTextInput(edit, inputArgs);
				if (inputArgs.Cancel)
					return;
			}

			edit.ReplaceText(start, length, text);
			SetOwnCaret(edit, start + text.Length);
		}
	}
}
#endif
