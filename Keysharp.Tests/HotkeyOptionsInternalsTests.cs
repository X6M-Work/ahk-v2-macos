namespace Keysharp.Tests;

[Category("Internal"), Category("Curated")]
public class HotkeyOptionsInternalsTests : TestRunner
{
	[TestCase("T2P-3B0S1I100", 2, -3, false, true, 100)]
	[TestCase("t255 p+7 b s0 i0", 12, 7, true, false, 0)]
	[TestCase("T1T3P-2P5B1B0S0SI", 3, 5, false, true, 0)]
	[TestCase("T\t+2P\r\n-3B0S1I 100", 2, -3, false, true, 100)]
	[TestCase("T2P999999999999999999999B0S1I0", 2, int.MaxValue, false, true, 0)]
	[TestCase("T2P-999999999999999999999B0S1I0", 2, int.MinValue, false, true, 0)]
	public void Settings(string options, int threads, int priority, bool buffer, bool exempt, long level)
	{
		var hotkey = CreateHotkey();
		Assert.That(HotkeyDefinition.Dynamic(s, "F24", options, null, 0), Is.EqualTo(ResultType.Ok));
		var variant = hotkey.firstVariant;
		Assert.That(variant.maxThreads, Is.EqualTo(threads));
		Assert.That(variant.priority, Is.EqualTo(priority));
		Assert.That(variant.maxThreadsBuffer, Is.EqualTo(buffer));
		Assert.That(variant.suspendExempt, Is.EqualTo(exempt));
		Assert.That(variant.inputLevel, Is.EqualTo(level));
	}

	[TestCase("P2Z"), TestCase("T0"), TestCase("T256"), TestCase("T-1"), TestCase("T")]
	[TestCase("I101"), TestCase("I-1"), TestCase("B2"), TestCase("S2"), TestCase("O")]
	[TestCase("On1"), TestCase("P0x01B"), TestCase("P+"), TestCase("\n"), TestCase("ſ")]
	public void InvalidOptionsLeaveCallbackAndSettingsUntouched(string options)
	{
		var hotkey = CreateHotkey();
		var variant = hotkey.firstVariant;
		variant.priority = 7;
		var binding = variant.FindBinding(s.EventScheduler);
		var callback = binding.Callback;
		using var scope = Keysharp.Runtime.Flow.EnterTry();
		var replacement = new KeysharpFunc((Func<object, object>)(_ => "replacement"));
		Assert.IsInstanceOf<ValueError>(Assert.Throws<KeysharpException>(() =>
			HotkeyDefinition.Dynamic(s, "F24", options, replacement, 0)).UserError);
		Assert.That(binding.Callback, Is.SameAs(callback));
		Assert.That(variant.priority, Is.EqualTo(7));
		Assert.That(binding.IsActive, Is.True);
		Assert.IsInstanceOf<ValueError>(Assert.Throws<KeysharpException>(() =>
			HotkeyDefinition.Dynamic(s, "F23", options, replacement, 0)).UserError);
		Assert.That(s.HotkeyData.shk, Has.Length.EqualTo(1));
	}

	[Test]
	public void ActionTakesPrecedenceOverOptions()
	{
		var hotkey = CreateHotkey();
		Assert.That(HotkeyDefinition.Dynamic(s, "F24", "Off", null, HotkeyDefinition.HOTKEY_ID_ON), Is.EqualTo(ResultType.Ok));
		Assert.That(hotkey.firstVariant.FindBinding(s.EventScheduler).IsActive, Is.True);
	}

	private HotkeyDefinition CreateHotkey()
	{
		var hotkey = new HotkeyDefinition(s, 0, new KeysharpFunc((Func<object, object>)(_ => "")), 0, "F24", 0);
		hotkey.keybdHookMandatory = true;
		s.HotkeyData.shk = [hotkey];
		return hotkey;
	}
}
