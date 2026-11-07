namespace Keysharp.Internals.Window.MacOS
{
	/// <summary>
	/// Snapshot of a macOS Accessibility (<c>AXUIElement</c>) control's identifying attributes used when matching
	/// a control selector (<c>ClassNN</c>, <c>AXRole</c> + index, title, description, identifier, or value).
	/// </summary>
	internal readonly record struct MacControlCandidate(
		string Role,
		string Title,
		string Description,
		string Identifier,
		string Value);

	/// <summary>
	/// Parses and evaluates control selectors for foreign macOS windows inspected via Accessibility (<c>AXUIElement</c>).
	/// Supports both native macOS roles with 1-based indices (e.g. <c>AXButton1</c>, <c>AXTextField2</c>),
	/// AutoHotkey/Win32 <c>ClassNN</c> aliases (e.g. <c>Button1</c>, <c>Edit1</c>, <c>Static1</c>, <c>ComboBox1</c>,
	/// <c>ListBox1</c>, <c>Tab1</c>), and text/title/description/identifier matching.
	/// </summary>
	internal static class MacControlSelector
	{
		private static readonly Dictionary<string, string[]> RoleAliases = new(StringComparer.OrdinalIgnoreCase)
		{
			["Button"] = ["AXButton", "AXCheckBox", "AXRadioButton", "AXPopUpButton", "AXMenuButton", "AXDisclosureTriangle"],
			["Edit"] = ["AXTextField", "AXTextArea", "AXSearchField", "AXSecureTextField", "AXComboBox"],
			["Static"] = ["AXStaticText"],
			["ComboBox"] = ["AXComboBox", "AXPopUpButton"],
			["ListBox"] = ["AXList", "AXTable", "AXOutline"],
			["ListView"] = ["AXTable", "AXOutline", "AXList"],
			["SysListView32"] = ["AXTable", "AXOutline", "AXList"],
			["TreeView"] = ["AXOutline"],
			["SysTreeView32"] = ["AXOutline"],
			["Tab"] = ["AXTabGroup", "AXRadioGroup"],
			["SysTabControl32"] = ["AXTabGroup", "AXRadioGroup"],
			["Slider"] = ["AXSlider"],
			["msctls_trackbar32"] = ["AXSlider"],
			["Progress"] = ["AXProgressIndicator"],
			["msctls_progress32"] = ["AXProgressIndicator"]
		};

		/// <summary>
		/// Attempts to parse a selector as a role or <c>ClassNN</c> with a 1-based instance index
		/// (for example <c>"Button1"</c>, <c>"Edit2"</c>, <c>"AXButton1"</c>, or bare <c>"AXTextField"</c>).
		/// </summary>
		internal static bool TryParseRoleSelector(string selector, out string[] targetRoles, out int oneBasedIndex)
		{
			targetRoles = null;
			oneBasedIndex = 0;

			if (string.IsNullOrWhiteSpace(selector))
				return false;

			var trimmed = selector.AsSpan().Trim();
			var digitStart = trimmed.Length;

			while (digitStart > 0 && char.IsAsciiDigit(trimmed[digitStart - 1]))
				digitStart--;

			var prefixSpan = trimmed[..digitStart];
			var numberSpan = trimmed[digitStart..];

			if (prefixSpan.IsEmpty)
				return false;

			// Keep Win32 class names whose fixed suffix ends with "32" intact when followed by an instance index (e.g. SysListView321 -> SysListView32 + 1).
			if (prefixSpan.EndsWith("SysListView", StringComparison.OrdinalIgnoreCase)
				|| prefixSpan.EndsWith("SysTreeView", StringComparison.OrdinalIgnoreCase)
				|| prefixSpan.EndsWith("SysTabControl", StringComparison.OrdinalIgnoreCase)
				|| prefixSpan.EndsWith("msctls_trackbar", StringComparison.OrdinalIgnoreCase)
				|| prefixSpan.EndsWith("msctls_progress", StringComparison.OrdinalIgnoreCase))
			{
				if (numberSpan.StartsWith("32", StringComparison.Ordinal) && numberSpan.Length > 2)
				{
					prefixSpan = trimmed[..(digitStart + 2)];
					numberSpan = numberSpan[2..];
				}
				else if (numberSpan.Equals("32", StringComparison.Ordinal))
				{
					prefixSpan = trimmed;
					numberSpan = ReadOnlySpan<char>.Empty;
				}
			}

			var prefix = prefixSpan.ToString();

			if (!numberSpan.IsEmpty)
			{
				if (!int.TryParse(numberSpan, NumberStyles.None, CultureInfo.InvariantCulture, out oneBasedIndex) || oneBasedIndex < 1)
					return false;
			}
			else
			{
				// Only treat a bare selector without trailing digits as a role selector if it is an explicit AX* role or known ClassNN alias.
				if (!prefix.StartsWith("AX", StringComparison.OrdinalIgnoreCase) && !RoleAliases.ContainsKey(prefix))
					return false;

				oneBasedIndex = 1;
			}

			if (RoleAliases.TryGetValue(prefix, out var mappedRoles))
			{
				targetRoles = mappedRoles;
				return true;
			}

			if (prefix.StartsWith("AX", StringComparison.OrdinalIgnoreCase) && prefix.Length > 2)
			{
				targetRoles = [prefix];
				return true;
			}

			return false;
		}

		/// <summary>
		/// Returns whether <paramref name="candidateRole"/> matches any role in <paramref name="targetRoles"/>.
		/// </summary>
		internal static bool MatchesRole(string candidateRole, IReadOnlyList<string> targetRoles)
		{
			if (string.IsNullOrEmpty(candidateRole) || targetRoles == null || targetRoles.Count == 0)
				return false;

			for (var i = 0; i < targetRoles.Count; i++)
			{
				if (string.Equals(candidateRole, targetRoles[i], StringComparison.OrdinalIgnoreCase))
					return true;
			}

			return false;
		}

		/// <summary>
		/// Returns whether <paramref name="candidate"/> matches a text/title/description/identifier selector.
		/// </summary>
		internal static bool MatchesText(in MacControlCandidate candidate, string selector)
		{
			if (string.IsNullOrEmpty(selector))
				return false;

			return MatchesField(candidate.Title, selector)
				|| MatchesField(candidate.Description, selector)
				|| MatchesField(candidate.Identifier, selector)
				|| MatchesField(candidate.Value, selector);
		}

		/// <summary>
		/// Resolves the best-effort readable text of a control from its Accessibility attributes:
		/// prefers <c>AXValue</c> when non-empty, then <c>AXTitle</c>, then <c>AXDescription</c>.
		/// </summary>
		internal static string ExtractControlText(in MacControlCandidate candidate)
		{
			if (!string.IsNullOrEmpty(candidate.Value))
				return candidate.Value;

			if (!string.IsNullOrEmpty(candidate.Title))
				return candidate.Title;

			return candidate.Description ?? string.Empty;
		}

		/// <summary>
		/// Builds the 1-based <c>AXRoleN</c> <c>ClassNN</c> list for all candidates that have a non-empty role.
		/// </summary>
		internal static List<string> BuildClassNNs(IReadOnlyList<MacControlCandidate> candidates)
		{
			var result = new List<string>(candidates?.Count ?? 0);

			if (candidates == null || candidates.Count == 0)
				return result;

			var counts = new Dictionary<string, int>(StringComparer.OrdinalIgnoreCase);

			for (var i = 0; i < candidates.Count; i++)
			{
				var role = candidates[i].Role;

				if (string.IsNullOrWhiteSpace(role))
					continue;

				var next = counts.GetValueOrDefault(role) + 1;
				counts[role] = next;
				result.Add($"{role}{next.ToString(CultureInfo.InvariantCulture)}");
			}

			return result;
		}

		/// <summary>
		/// Computes the canonical 1-based <c>AXRoleN</c> <c>ClassNN</c> for the candidate at <paramref name="matchIndex"/>.
		/// </summary>
		internal static string GetClassNNAt(IReadOnlyList<MacControlCandidate> candidates, int matchIndex)
		{
			if (candidates == null || matchIndex < 0 || matchIndex >= candidates.Count)
				return string.Empty;

			var targetRole = candidates[matchIndex].Role;

			if (string.IsNullOrWhiteSpace(targetRole))
				return string.Empty;

			var count = 0;

			for (var i = 0; i <= matchIndex; i++)
			{
				if (string.Equals(candidates[i].Role, targetRole, StringComparison.OrdinalIgnoreCase))
					count++;
			}

			return $"{targetRole}{count.ToString(CultureInfo.InvariantCulture)}";
		}

		/// <summary>
		/// Finds the 0-based index of the matching control in <paramref name="candidates"/> for <paramref name="selector"/>,
		/// or <c>-1</c> if no candidate matches.
		/// </summary>
		internal static int FindMatchIndex(IReadOnlyList<MacControlCandidate> candidates, string selector)
		{
			if (candidates == null || candidates.Count == 0 || string.IsNullOrWhiteSpace(selector))
				return -1;

			var trimmed = selector.Trim();

			if (TryParseRoleSelector(trimmed, out var roles, out var nth))
			{
				var seen = 0;

				for (var i = 0; i < candidates.Count; i++)
				{
					if (MatchesRole(candidates[i].Role, roles) && ++seen == nth)
						return i;
				}
			}

			// Exact match on Title, Identifier, Description, or Value first.
			for (var i = 0; i < candidates.Count; i++)
			{
				var c = candidates[i];

				if (string.Equals(c.Title, trimmed, StringComparison.OrdinalIgnoreCase)
					|| string.Equals(c.Identifier, trimmed, StringComparison.OrdinalIgnoreCase)
					|| string.Equals(c.Description, trimmed, StringComparison.OrdinalIgnoreCase)
					|| string.Equals(c.Value, trimmed, StringComparison.OrdinalIgnoreCase))
					return i;
			}

			// Fallback to substring/prefix match.
			for (var i = 0; i < candidates.Count; i++)
			{
				if (MatchesText(candidates[i], trimmed))
					return i;
			}

			return -1;
		}

		/// <summary>
		/// Finds the 0-based index of the control in <paramref name="candidates"/> whose screen-coordinate
		/// rectangle in <paramref name="bounds"/> contains <paramref name="point"/>, or <c>-1</c> if none matches.
		/// When <paramref name="simpleMode"/> is <see langword="false"/> (the default for <c>MouseGetPos</c>),
		/// prefers the smallest-area containing control (breaking ties in favor of deeper/later controls).
		/// When <paramref name="simpleMode"/> is <see langword="true"/> (<c>Flag &amp; 1</c>), returns the first
		/// top-level/shallowest control in traversal order whose bounds contain <paramref name="point"/>.
		/// </summary>
		internal static int FindMatchIndexAtPoint(
			IReadOnlyList<MacControlCandidate> candidates,
			IReadOnlyList<Rectangle> bounds,
			Point point,
			bool simpleMode = false)
		{
			if (candidates == null || bounds == null)
				return -1;

			var count = Math.Min(candidates.Count, bounds.Count);

			if (count == 0)
				return -1;

			var bestIndex = -1;
			var bestArea = long.MaxValue;

			for (var i = 0; i < count; i++)
			{
				if (string.IsNullOrWhiteSpace(candidates[i].Role))
					continue;

				var rect = bounds[i];

				if (rect.Width <= 0 || rect.Height <= 0 || !rect.Contains(point))
					continue;

				if (simpleMode)
					return i;

				var area = (long)rect.Width * rect.Height;

				if (bestIndex < 0 || area <= bestArea)
				{
					bestArea = area;
					bestIndex = i;
				}
			}

			return bestIndex;
		}

		private static bool MatchesField(string fieldValue, string selector)
			=> !string.IsNullOrEmpty(fieldValue)
				&& fieldValue.Contains(selector, StringComparison.OrdinalIgnoreCase);
	}
}
