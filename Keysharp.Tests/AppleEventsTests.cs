namespace Keysharp.Tests;

/// <summary>
/// Exercises the parts of the Apple Events layer that do not need macOS: four-character codes and the
/// scripting-definition parser, which between them decide every name and keyword the rest of the layer sends.
/// The parser is deliberately free of a platform guard so these run on every host; the sending, marshalling
/// and notification paths need real hardware and are covered by the on-device protocol instead.
/// </summary>
[TestFixture, Category("Internal"), Category("Curated")]
public class AppleEventsTests : TestRunner
{
	/// <summary>
	/// A scripting definition small enough to read but covering the shapes that cost a debugging round when
	/// they are wrong: an eight-character command code, inheritance, a class-extension, an explicit plural,
	/// terms containing spaces, synonyms, enumerations, and a name defined by two suites at once.
	/// </summary>
	private const string FixtureSdef = """
		<?xml version="1.0" encoding="UTF-8"?>
		<dictionary title="Fixture">
			<suite name="Standard Suite" code="core" description="Common commands.">
				<command name="get" code="coregetd" description="Get the data for an object.">
					<direct-parameter type="specifier"/>
					<parameter name="as" code="rtyp" type="type" optional="yes"/>
					<result type="any"/>
				</command>
				<command name="count" code="corecnte">
					<direct-parameter type="specifier"/>
					<parameter name="each" code="kocl" type="type" optional="yes"/>
					<result type="integer"/>
				</command>
				<command name="close" code="coreclos">
					<direct-parameter type="specifier"/>
					<parameter name="saving" code="savo" optional="yes">
						<type type="save options"/>
					</parameter>
					<synonym name="shut"/>
				</command>
				<enumeration name="save options" code="savo">
					<enumerator name="yes" code="yes "/>
					<enumerator name="no" code="no  "/>
					<enumerator name="ask" code="ask ">
						<synonym name="prompt"/>
					</enumerator>
				</enumeration>
				<class name="item" code="cobj" description="A scriptable object.">
					<property name="class" code="pcls" type="type" access="r"/>
					<property name="name" code="pnam" type="text"/>
				</class>
				<class name="application" code="capp" inherits="item" plural="applications">
					<property name="frontmost" code="pisf" type="boolean" access="r"/>
					<element type="window"/>
					<element type="document"/>
				</class>
				<class name="window" code="cwin" inherits="item" plural="windows">
					<property name="index" code="pidx" type="integer"/>
					<property name="file name" code="ppth" type="text" access="r">
						<synonym name="path"/>
					</property>
					<responds-to command="close"><cocoa method="handleClose:"/></responds-to>
				</class>
				<class name="document" code="docu" inherits="item"/>
			</suite>
			<suite name="Fixture Suite" code="fixt" description="The application's own terminology.">
				<command name="refresh" code="fixtrfsh">
					<direct-parameter type="specifier" optional="yes"/>
				</command>
				<command name="count" code="fixtcnt2" description="Same name, different event.">
					<result type="integer"/>
				</command>
				<class-extension extends="application">
					<property name="theme" code="thme" type="text"/>
					<element type="tab"/>
				</class-extension>
				<class name="tab" code="ctab" inherits="item"/>
			</suite>
		</dictionary>
		""";

	private static AESdefDictionary Fixture(Func<string, string> resolveInclude = null)
		=> AESdef.Parse(FixtureSdef, resolveInclude);

	// ---- four-character codes -----------------------------------------------------------------

	[Test]
	public void FourCharCodesRoundTrip()
	{
		Assert.That(AEFourCharCode.Unpack(AEFourCharCode.Pack("utxt")), Is.EqualTo("utxt"));
		// Spaces are significant: "ID  " and "all " are ordinary codes.
		Assert.That(AEFourCharCode.Unpack(AEFourCharCode.Pack("ID  ")), Is.EqualTo("ID  "));
		Assert.That(AEFourCharCode.Unpack(AEFourCharCode.Pack("all ")), Is.EqualTo("all "));
	}

	[Test]
	public void FourCharCodesPackBigEndian() =>
		// 'long' is 0x6C6F6E67: the first character occupies the most significant byte.
		Assert.That(AEFourCharCode.Pack("long"), Is.EqualTo(0x6C6F6E67u));

	[Test]
	public void FourCharCodesRejectWrongLength()
	{
		Assert.That(AEFourCharCode.TryPack("utf".AsSpan(), out _), Is.False);
		Assert.That(AEFourCharCode.TryPack("utext".AsSpan(), out _), Is.False);
		Assert.That(AEFourCharCode.TryPack("".AsSpan(), out _), Is.False);
		_ = Assert.Throws<ArgumentException>(() => AEFourCharCode.Pack("nope!"));
	}

	// ---- canonical names -----------------------------------------------------------------------

	[Test]
	public void KeyFoldsSpacesUnderscoresAndCase()
	{
		// A script cannot write "file name", so every spelling it can write has to reach the same term.
		Assert.That(AESdef.Key("file name"), Is.EqualTo("filename"));
		Assert.That(AESdef.Key("FileName"), Is.EqualTo("filename"));
		Assert.That(AESdef.Key("file_name"), Is.EqualTo("filename"));
		Assert.That(AESdef.Key("FILE NAME"), Is.EqualTo("filename"));
	}

	// ---- commands -------------------------------------------------------------------------------

	[Test]
	public void CommandCodeSplitsIntoClassAndEvent()
	{
		var command = Fixture().CommandsByKey["get"].Single();
		Assert.That(AEFourCharCode.Unpack(command.EventClass), Is.EqualTo("core"));
		Assert.That(AEFourCharCode.Unpack(command.EventId), Is.EqualTo("getd"));
		Assert.That(command.HasDirectParameter, Is.True);
	}

	[Test]
	public void CommandParametersCarryTheirKeywords()
	{
		var close = Fixture().CommandsByKey["close"].Single();
		Assert.That(close.TryGetParameter("saving", out var saving), Is.True);
		Assert.That(AEFourCharCode.Unpack(saving.Code), Is.EqualTo("savo"));
		// The type came from a child element rather than an attribute.
		Assert.That(saving.TypeName, Is.EqualTo("save options"));
		Assert.That(saving.Optional, Is.True);
	}

	[Test]
	public void CommandSynonymsResolveToTheSameCommand()
	{
		var dict = Fixture();
		Assert.That(dict.CommandsByKey.ContainsKey("shut"), Is.True);
		Assert.That(dict.CommandsByKey["shut"].Single().EventId, Is.EqualTo(dict.CommandsByKey["close"].Single().EventId));
	}

	[Test]
	public void SameNameInTwoSuitesStaysAmbiguous()
	{
		// Two different events sharing a name is what the object model has to report rather than guess at.
		var counts = Fixture().CommandsByKey["count"];
		Assert.That(counts.Count, Is.EqualTo(2));
		Assert.That(counts.Select(c => c.Suite), Is.EquivalentTo(new[] { "Standard Suite", "Fixture Suite" }));
	}

	// ---- classes ---------------------------------------------------------------------------------

	[Test]
	public void PropertiesAreFoundThroughInheritance()
	{
		var dict = Fixture();
		// "name" is defined on item, which window inherits from.
		var name = dict.FindProperty("window", "name");
		Assert.That(name, Is.Not.Null);
		Assert.That(AEFourCharCode.Unpack(name.Code), Is.EqualTo("pnam"));
		Assert.That(dict.FindProperty("window", "index"), Is.Not.Null);
	}

	[Test]
	public void PropertyAccessDefaultsToReadWrite()
	{
		var dict = Fixture();
		var name = dict.FindProperty("window", "name");
		using (Assert.EnterMultipleScope())
		{
			Assert.That(name.CanRead, Is.True);
			Assert.That(name.CanWrite, Is.True);
		}

		var path = dict.FindProperty("window", "filename");
		using (Assert.EnterMultipleScope())
		{
			Assert.That(path.CanRead, Is.True);
			Assert.That(path.CanWrite, Is.False);
		}
	}

	[Test]
	public void PropertySynonymResolves()
	{
		var dict = Fixture();
		Assert.That(dict.FindProperty("window", "path")?.Code, Is.EqualTo(dict.FindProperty("window", "filename")?.Code));
	}

	[Test]
	public void ClassExtensionMergesIntoTheExistingClass()
	{
		var dict = Fixture();
		// "theme" and the tab element were added by a different suite than the one defining application.
		Assert.That(dict.FindProperty("application", "theme"), Is.Not.Null);
		Assert.That(dict.FindProperty("application", "frontmost"), Is.Not.Null);
		Assert.That(dict.FindElement("application", "tabs"), Is.Not.Null);
	}

	[Test]
	public void ElementsResolveByPlural()
	{
		var dict = Fixture();
		Assert.That(dict.FindElement("application", "windows")?.Name, Is.EqualTo("window"));
		// document has no explicit plural, so it falls back to the name plus s.
		Assert.That(dict.FindElement("application", "documents")?.Name, Is.EqualTo("document"));
		Assert.That(dict.FindElement("application", "windoze"), Is.Null);
	}

	[Test]
	public void ClassesAreReachableByCode()
	{
		var dict = Fixture();
		Assert.That(dict.ClassesByCode[AEFourCharCode.Pack("cwin")].Name, Is.EqualTo("window"));
		Assert.That(dict.ClassesByCode[AEFourCharCode.Pack("capp")].Name, Is.EqualTo("application"));
	}

	[Test]
	public void RespondsToIsRecorded()
	{
		Assert.That(Fixture().RespondsTo("window", "close"), Is.True);
		Assert.That(Fixture().RespondsTo("document", "close"), Is.False);
	}

	// ---- enumerations -----------------------------------------------------------------------------

	[Test]
	public void EnumeratorsMapBothWays()
	{
		var dict = Fixture();
		var options = dict.EnumerationsByName["save options"];
		Assert.That(AEFourCharCode.Unpack(options.Enumerators["yes"]), Is.EqualTo("yes "));
		Assert.That(AEFourCharCode.Unpack(options.Enumerators["ask"]), Is.EqualTo("ask "));
		// A synonym reaches the same enumerator.
		Assert.That(options.Enumerators["prompt"], Is.EqualTo(options.Enumerators["ask"]));
		Assert.That(dict.EnumeratorNamesByCode[AEFourCharCode.Pack("no  ")], Is.EqualTo("no"));
	}

	// ---- includes and robustness --------------------------------------------------------------------

	[Test]
	public void IncludedSuitesAreMerged()
	{
		const string included = """
			<?xml version="1.0" encoding="UTF-8"?>
			<dictionary title="Included">
				<suite name="Extra Suite" code="extr">
					<command name="reveal" code="extrrevl"/>
				</suite>
			</dictionary>
			""";
		const string host = """
			<?xml version="1.0" encoding="UTF-8"?>
			<dictionary title="Host" xmlns:xi="http://www.w3.org/2003/XInclude">
				<xi:include href="file:///System/Library/ScriptingDefinitions/CocoaStandard.sdef"/>
				<suite name="Own Suite" code="ownn">
					<command name="ping" code="ownnping"/>
				</suite>
			</dictionary>
			""";
		var dict = AESdef.Parse(host, _ => included);
		Assert.That(dict.CommandsByKey.ContainsKey("ping"), Is.True);
		Assert.That(dict.CommandsByKey.ContainsKey("reveal"), Is.True);
		Assert.That(dict.Suites, Does.Contain("Extra Suite"));
	}

	[Test]
	public void AMissingIncludeStillYieldsTheApplicationsOwnTerminology()
	{
		const string host = """
			<?xml version="1.0" encoding="UTF-8"?>
			<dictionary title="Host" xmlns:xi="http://www.w3.org/2003/XInclude">
				<xi:include href="file:///nope.sdef"/>
				<suite name="Own Suite" code="ownn">
					<command name="ping" code="ownnping"/>
				</suite>
			</dictionary>
			""";
		var dict = AESdef.Parse(host, _ => null);
		Assert.That(dict.CommandsByKey.ContainsKey("ping"), Is.True);
	}

	[Test]
	public void MalformedDefinitionsAreReportedNotSwallowed()
		=> Assert.Throws<FormatException>(() => AESdef.Parse("<dictionary><suite>"));

	[Test]
	public void EmptyDefinitionYieldsAnEmptyDictionary()
	{
		Assert.That(AESdef.Parse("").Suites, Is.Empty);
		Assert.That(AESdef.Parse(null).CommandsByKey, Is.Empty);
	}

	[Test]
	public void InheritanceCyclesDoNotHang()
	{
		const string cyclic = """
			<?xml version="1.0" encoding="UTF-8"?>
			<dictionary title="Cyclic">
				<suite name="S" code="ssss">
					<class name="a" code="aaaa" inherits="b"/>
					<class name="b" code="bbbb" inherits="a"/>
				</suite>
			</dictionary>
			""";
		var dict = AESdef.Parse(cyclic);
		Assert.That(dict.Ancestry("a").Count(), Is.EqualTo(2));
		Assert.That(dict.FindProperty("a", "nothing"), Is.Null);
	}

	[Test]
	public void ARestatedCommandMergesRatherThanBeingDropped()
	{
		// An application commonly restates a standard command to add its own parameters. Both definitions are
		// the same event, so the second must extend the first instead of being discarded as a duplicate.
		const string sdef = """
			<?xml version="1.0" encoding="UTF-8"?>
			<dictionary title="Restated">
				<suite name="Standard Suite" code="core">
					<command name="open" code="aevtodoc">
						<direct-parameter type="file"/>
					</command>
				</suite>
				<suite name="Own Suite" code="ownn">
					<command name="open" code="aevtodoc">
						<parameter name="reading" code="rdng" type="boolean" optional="yes"/>
					</command>
				</suite>
			</dictionary>
			""";
		var dict = AESdef.Parse(sdef);
		var open = dict.CommandsByKey["open"];
		Assert.That(open.Count, Is.EqualTo(1), "the same event under one name is one command");
		using (Assert.EnterMultipleScope())
		{
			Assert.That(open[0].HasDirectParameter, Is.True);
			Assert.That(open[0].TryGetParameter("reading", out _), Is.True);
		}
	}

	[Test]
	public void AMalformedCodeSkipsOnlyThatTerm()
	{
		// A dictionary is hundreds of terms; one unusable code must not cost the application all of them,
		// because the failure is cached and would leave the application permanently unusable.
		const string sdef = """
			<?xml version="1.0" encoding="UTF-8"?>
			<dictionary title="Damaged">
				<suite name="S" code="ssss">
					<command name="good" code="ssssgood"/>
					<command name="shortcode" code="sss"/>
					<command name="widechar" code="ssss☃ood"/>
					<class name="thing" code="thng">
						<property name="fine" code="fine"/>
						<property name="broken" code="ab"/>
					</class>
				</suite>
			</dictionary>
			""";
		var dict = AESdef.Parse(sdef);
		using (Assert.EnterMultipleScope())
		{
			Assert.That(dict.CommandsByKey.ContainsKey("good"), Is.True);
			Assert.That(dict.CommandsByKey.ContainsKey("shortcode"), Is.False);
			Assert.That(dict.CommandsByKey.ContainsKey("widechar"), Is.False);
			Assert.That(dict.FindProperty("thing", "fine"), Is.Not.Null);
			Assert.That(dict.FindProperty("thing", "broken"), Is.Null);
		}
	}

	[Test]
	public void PropertyCodesAreIndexedForRecordKeys()
	{
		// Writing "with properties {name: ...}" needs the keyword without knowing the class.
		var dict = Fixture();
		Assert.That(dict.PropertyCodesByKey["name"], Is.EqualTo(AEFourCharCode.Pack("pnam")));
		Assert.That(dict.PropertyNamesByCode[AEFourCharCode.Pack("ppth")], Is.EqualTo("file name"));
	}

	[Test]
	public void AppNameWithDotAppSuffixNormalizesToApplicationName()
	{
		using (Assert.EnterMultipleScope())
		{
			Assert.That(AESdef.NormalizeTargetName("Finder.app"), Is.EqualTo("Finder"));
			Assert.That(AESdef.NormalizeTargetName("  Visual Studio Code.APP "), Is.EqualTo("Visual Studio Code"));
			Assert.That(AESdef.NormalizeTargetName("/System/Library/CoreServices/Finder.app"), Is.EqualTo("/System/Library/CoreServices/Finder.app"));
			Assert.That(AESdef.NormalizeTargetName("com.apple.finder"), Is.EqualTo("com.apple.finder"));
			Assert.That(AESdef.NormalizeTargetName("pid:1234"), Is.EqualTo("pid:1234"));
		}
	}

	[Test]
	public void MacNotificationArgsPreserveSpecialCharactersAndDefaultTitle()
	{
		var args = Ks.BuildMacNotificationArgs("Line with \"quotes\" and \\backslash", "Custom Title", "Sub", "Ping");
		using (Assert.EnterMultipleScope())
		{
			Assert.That(args, Has.Count.EqualTo(4));
			Assert.That(args[0], Is.EqualTo("Line with \"quotes\" and \\backslash"));
			Assert.That(args[1], Is.EqualTo("Custom Title"));
			Assert.That(args[2], Is.EqualTo("Sub"));
			Assert.That(args[3], Is.EqualTo("Ping"));
			Assert.That(Ks.BuildMacNotificationArgs("Body")[1], Is.Not.Empty);
		}
	}

	[Test]
	public void MacShortcutArgsFormatRunAndStdinFlags()
	{
		using (Assert.EnterMultipleScope())
		{
			Assert.That(Ks.BuildMacShortcutArgs("My Shortcut", hasStdinInput: false),
				Is.EqualTo(new[] { "run", "My Shortcut" }));
			Assert.That(Ks.BuildMacShortcutArgs("Process Text", hasStdinInput: true),
				Is.EqualTo(new[] { "run", "Process Text", "-i", "-" }));
		}
	}

	[Test]
	public void MacControlSelectorParsesRolesClassNNAndMatchesCandidates()
	{
		Keysharp.Internals.Window.MacOS.MacControlCandidate[] candidates =
		[
			new("AXStaticText", "", "Username label", "lblUser", "Username:"),
			new("AXTextField", "", "Username input", "txtUser", "alice"),
			new("AXButton", "Cancel", "Cancel dialog", "btnCancel", ""),
			new("AXButton", "OK", "Confirm dialog", "btnOk", ""),
			new("AXTable", "", "Results list", "tblResults", "")
		];

		using (Assert.EnterMultipleScope())
		{
			Assert.That(Keysharp.Internals.Window.MacOS.MacControlSelector.FindMatchIndex(candidates, "Button1"), Is.EqualTo(2));
			Assert.That(Keysharp.Internals.Window.MacOS.MacControlSelector.FindMatchIndex(candidates, "Button2"), Is.EqualTo(3));
			Assert.That(Keysharp.Internals.Window.MacOS.MacControlSelector.FindMatchIndex(candidates, "AXButton2"), Is.EqualTo(3));
			Assert.That(Keysharp.Internals.Window.MacOS.MacControlSelector.FindMatchIndex(candidates, "Edit1"), Is.EqualTo(1));
			Assert.That(Keysharp.Internals.Window.MacOS.MacControlSelector.FindMatchIndex(candidates, "Static1"), Is.EqualTo(0));
			Assert.That(Keysharp.Internals.Window.MacOS.MacControlSelector.FindMatchIndex(candidates, "SysListView321"), Is.EqualTo(4));
			Assert.That(Keysharp.Internals.Window.MacOS.MacControlSelector.FindMatchIndex(candidates, "OK"), Is.EqualTo(3));
			Assert.That(Keysharp.Internals.Window.MacOS.MacControlSelector.FindMatchIndex(candidates, "btnCancel"), Is.EqualTo(2));
			Assert.That(Keysharp.Internals.Window.MacOS.MacControlSelector.FindMatchIndex(candidates, "Confirm dialog"), Is.EqualTo(3));
			Assert.That(Keysharp.Internals.Window.MacOS.MacControlSelector.FindMatchIndex(candidates, "NoSuchControl"), Is.EqualTo(-1));
			Assert.That(Keysharp.Internals.Window.MacOS.MacControlSelector.ExtractControlText(candidates[1]), Is.EqualTo("alice"));
			Assert.That(Keysharp.Internals.Window.MacOS.MacControlSelector.ExtractControlText(candidates[3]), Is.EqualTo("OK"));
			Assert.That(Keysharp.Internals.Window.MacOS.MacControlSelector.BuildClassNNs(candidates),
				Is.EqualTo(new[] { "AXStaticText1", "AXTextField1", "AXButton1", "AXButton2", "AXTable1" }));
			Assert.That(Keysharp.Internals.Window.MacOS.MacControlSelector.GetClassNNAt(candidates, 3), Is.EqualTo("AXButton2"));
		}
	}

	[Test]
	public void MacControlSelectorHitTestingAtPointHonorsSimpleAndDeepModes()
	{
		Keysharp.Internals.Window.MacOS.MacControlCandidate[] candidates =
		[
			new("AXGroup", "Credentials", "", "grpCreds", ""),
			new("AXButton", "Login", "", "btnLogin", ""),
			new("AXScrollArea", "", "", "scrollBio", ""),
			new("AXTextArea", "", "", "txtBio", "Hello")
		];
		Rectangle[] bounds =
		[
			new(100, 100, 300, 200),
			new(120, 130, 80, 30),
			new(100, 320, 300, 120),
			new(100, 320, 300, 120)
		];

		using (Assert.EnterMultipleScope())
		{
			// Default deep mode (simpleMode: false) picks the smaller inner AXButton1 over the enclosing AXGroup1.
			var deepIdx = Keysharp.Internals.Window.MacOS.MacControlSelector.FindMatchIndexAtPoint(
				candidates, bounds, new Point(150, 145), simpleMode: false);
			Assert.That(deepIdx, Is.EqualTo(1));
			Assert.That(Keysharp.Internals.Window.MacOS.MacControlSelector.GetClassNNAt(candidates, deepIdx), Is.EqualTo("AXButton1"));

			// Simple mode (Flag & 1) picks the outer container AXGroup1 first in traversal order.
			var simpleIdx = Keysharp.Internals.Window.MacOS.MacControlSelector.FindMatchIndexAtPoint(
				candidates, bounds, new Point(150, 145), simpleMode: true);
			Assert.That(simpleIdx, Is.EqualTo(0));
			Assert.That(Keysharp.Internals.Window.MacOS.MacControlSelector.GetClassNNAt(candidates, simpleIdx), Is.EqualTo("AXGroup1"));

			// When container and child share identical bounds, deep mode prefers the deeper child (AXTextArea1).
			var equalBoundsDeepIdx = Keysharp.Internals.Window.MacOS.MacControlSelector.FindMatchIndexAtPoint(
				candidates, bounds, new Point(180, 360), simpleMode: false);
			Assert.That(equalBoundsDeepIdx, Is.EqualTo(3));
			Assert.That(Keysharp.Internals.Window.MacOS.MacControlSelector.GetClassNNAt(candidates, equalBoundsDeepIdx), Is.EqualTo("AXTextArea1"));

			// Point outside all controls returns -1.
			Assert.That(Keysharp.Internals.Window.MacOS.MacControlSelector.FindMatchIndexAtPoint(
				candidates, bounds, new Point(20, 20), simpleMode: false), Is.EqualTo(-1));
		}
	}

	[Test]
	public void RetinaPixelToScreenRoundTripMapsBackingPixelsToLogicalScreenCoordinates()
	{
		// Logical 200x100 region at screen (100, 50) backed by a 2x Retina 400x200 pixel capture.
		var logicalRegion = new ScreenRect(100, 50, 200, 100);
		var backingSize = new PixelSize(400, 200);

		var mapped = logicalRegion.PixelToScreen(new PixelPoint(240, 120), backingSize);
		var pixelBounds = logicalRegion.ScreenToPixelBounds(new ScreenRect(100, 50, 200, 100), backingSize);

		using (Assert.EnterMultipleScope())
		{
			Assert.That(mapped.X, Is.EqualTo(220));
			Assert.That(mapped.Y, Is.EqualTo(110));
			Assert.That(pixelBounds.X, Is.EqualTo(0));
			Assert.That(pixelBounds.Y, Is.EqualTo(0));
			Assert.That(pixelBounds.Width, Is.EqualTo(400));
			Assert.That(pixelBounds.Height, Is.EqualTo(200));
		}
	}

	[Test]
	public void MacKeychainAndSpotlightHelpersFormatArgumentsAndParsePaths()
	{
		using (Assert.EnterMultipleScope())
		{
			Assert.That(Ks.BuildMacKeychainGetArgs("MyService", "alice"),
				Is.EqualTo(new[] { "find-generic-password", "-s", "MyService", "-a", "alice", "-w" }));
			Assert.That(Ks.BuildMacKeychainSetArgs("MyService", "alice", "s3cr3t"),
				Is.EqualTo(new[] { "add-generic-password", "-U", "-s", "MyService", "-a", "alice", "-w", "s3cr3t" }));
			Assert.That(Ks.BuildMacKeychainDeleteArgs("MyService", "alice"),
				Is.EqualTo(new[] { "delete-generic-password", "-s", "MyService", "-a", "alice" }));
			Assert.That(Ks.BuildMacSpotlightArgs("kMDItemFSName == '*.ahk'"),
				Is.EqualTo(new[] { "kMDItemFSName == '*.ahk'" }));
			Assert.That(Ks.BuildMacSpotlightArgs("report", "/Users/alice/Documents"),
				Is.EqualTo(new[] { "-onlyin", "/Users/alice/Documents", "report" }));
			Assert.That(Ks.ParseSpotlightOutput("/Users/alice/a.ahk\n/Users/alice/b.ahk\n\n"),
				Is.EqualTo(new[] { "/Users/alice/a.ahk", "/Users/alice/b.ahk" }));
			Assert.That(Ks.ParseSpotlightOutput(""), Is.Empty);
		}
	}

#if OSX
	[Test]
	public void IndependentTargets()
	{
		using var started = new ManualResetEventSlim();
		using var release = new ManualResetEventSlim();
		using var finished = new ManualResetEventSlim();
		using var otherFinished = new ManualResetEventSlim();
		var target = Guid.NewGuid().ToString();

		AETargetQueue.Enqueue(target, () =>
		{
			started.Set();
			release.Wait();
			finished.Set();
		});

		try
		{
			Assert.That(started.Wait(5_000), Is.True);
			AETargetQueue.Enqueue(Guid.NewGuid().ToString(), otherFinished.Set);
			Assert.That(otherFinished.Wait(5_000), Is.True, "A blocked target delayed an independent target.");
		}
		finally
		{
			release.Set();
			Assert.That(finished.Wait(5_000), Is.True);
		}
	}

	[Test]
	public void TargetOrder()
	{
		using var started = new ManualResetEventSlim();
		using var release = new ManualResetEventSlim();
		using var finished = new ManualResetEventSlim();
		var target = Guid.NewGuid().ToString();
		var order = new List<int>();

		AETargetQueue.Enqueue(target, () =>
		{
			started.Set();
			release.Wait();
			order.Add(1);
		});

		try
		{
			Assert.That(started.Wait(5_000), Is.True);
			AETargetQueue.Enqueue(target, () => order.Add(2));
			AETargetQueue.Enqueue(target, () =>
			{
				order.Add(3);
				finished.Set();
			});
		}
		finally
		{
			release.Set();
		}

		Assert.That(finished.Wait(5_000), Is.True);
		Assert.That(order, Is.EqualTo(new[] { 1, 2, 3 }));
	}
#endif
}