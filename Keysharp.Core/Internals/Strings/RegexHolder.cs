using Keysharp.Builtins;
namespace Keysharp.Internals.Strings
{
	internal class RegexHolder
	{
		internal PcreRegex regex;
		internal (string Pattern, bool V20) CacheKey { get; }
		internal string[] groupNames;
		internal bool hasCallout;//Whether the pattern uses callouts; if not, matching can skip the callback path.

		internal RegexHolder((string Pattern, bool V20) key)
		{
			CacheKey = key;
			var n = key.Pattern;
			var optionsLength = Conversions.RegexOptionsLength(n);
			// The A option is PCRE's anchored option and nothing more: it anchors the match at the starting
			// position, where a \A in the pattern would anchor it at the start of the haystack.
			var settings = Conversions.ToRegexOptions(n.AsSpan(0, optionsLength > 0 ? optionsLength - 1 : 0));
			settings.Options |= PcreOptions.Compiled;
			var pattern = n.Substring(optionsLength);
			regex = CompilePattern(pattern, settings, key.V20,
				n.AsSpan(0, optionsLength > 0 ? optionsLength - 1 : 0).Contains('X'));

			var info = regex.PatternInfo;
			//Whether matching needs the (slower) callout callback path. Taken from the compiled pattern's callout
			//list (authoritative — covers numeric, named and translated callouts) plus the auto-callout option.
			hasCallout = (settings.Options & PcreOptions.AutoCallout) != 0 || info.Callouts.Any();
			groupNames = new string[info.CaptureCount + 1];

			foreach (var name in info.GroupNames)
			{
				foreach (var i in info.GetGroupIndexesByName(name))
					groupNames[i] = name;
			}

			for (int i = 0; i < groupNames.Length; i++)
				groupNames[i] ??= "";
		}

		// PCRE2 starting delimiters for a string callout, e.g. (?C'name'), (?C"name"), (?C{name}).
		private const string Pcre2CalloutDelimiters = "`'\"^%#${";

		private static PcreRegex CompilePattern(string pattern, PcreRegexSettings settings, bool v20, bool strict)
		{
			while (true)
			{
				PcreRegex compiled;
				try
				{
					compiled = new PcreRegex(pattern, settings);
				}
				catch (PcrePatternException error)
				{
					if (v20 && (TranslateUnknownEscape(ref pattern, error, strict)
						|| TranslateSpecialEscape(ref pattern, settings, strict)))
						continue;

					if (pattern.Contains("(?C", StringComparison.Ordinal))
					{
						var translated = TranslateCallouts(pattern);
						if (!string.Equals(pattern, translated, StringComparison.Ordinal))
						{
							pattern = translated;
							continue;
						}
					}
					throw;
				}

				if (v20 && TranslateSpecialEscape(ref pattern, settings, strict))
					continue;
				return compiled;
			}
		}

		private static bool TranslateUnknownEscape(ref string pattern, PcrePatternException error, bool strict)
		{
			if (strict || error.ErrorCode is not (PcreErrorCode.UnknownEscape or PcreErrorCode.UnsupportedEscapeSequence))
				return false;

			var offset = ErrorOffset(error);
			if (offset < 2 || offset > pattern.Length || pattern[offset - 2] != '\\'
				|| !"ijmoqyFIJMOTY".Contains(pattern[offset - 1]))
				return false;

			pattern = pattern.Remove(offset - 2, 1);
			return true;
		}

		private static bool TranslateSpecialEscape(ref string pattern, PcreRegexSettings settings, bool strict)
		{
			for (var i = 0; i + 1 < pattern.Length; i++)
			{
				if (pattern[i] != '\\')
					continue;
				var escaped = pattern[i + 1];
				if (escaped != 'o' && (escaped != 'x' || i + 2 < pattern.Length && char.IsAsciiHexDigit(pattern[i + 2])
					|| HasHexCodePoint(pattern.AsSpan(i + 2))))
					continue;

				var probe = string.Concat(pattern.AsSpan(0, i + 1), "j", pattern.AsSpan(i + 2));
				try
				{
					_ = new PcreRegex(probe, settings);
				}
				catch (PcrePatternException error)
				{
					if (error.ErrorCode != PcreErrorCode.UnknownEscape || ErrorOffset(error) != i + 2)
						continue;
					if (escaped == 'o' && strict)
						throw new PcrePatternException(PcreErrorCode.UnknownEscape, $"Unrecognized PCRE1 escape \\o at offset {i + 2}.");
					pattern = escaped == 'o' ? pattern.Remove(i, 1) : pattern.Insert(i + 2, "00");
					return true;
				}
			}
			return false;
		}

		private static int ErrorOffset(PcrePatternException error)
		{
			// PCRE.NET 1.6.1 exposes the compile offset only in this invariant message suffix.
			const string marker = " at offset ";
			var message = error.Message.AsSpan();
			var index = message.LastIndexOf(marker, StringComparison.Ordinal);
			return index >= 0 && message.EndsWith(".", StringComparison.Ordinal)
				&& int.TryParse(message.Slice(index + marker.Length, message.Length - index - marker.Length - 1),
					NumberStyles.None, CultureInfo.InvariantCulture, out var offset) ? offset : -1;
		}

		private static bool HasHexCodePoint(ReadOnlySpan<char> text)
		{
			if (text.Length < 3 || text[0] != '{' || !char.IsAsciiHexDigit(text[1]))
				return false;
			var i = 2;
			while (i < text.Length && char.IsAsciiHexDigit(text[i])) i++;
			return i < text.Length && text[i] == '}';
		}

		/// <summary>
		/// AutoHotkey (patched PCRE1) accepts an unquoted callout name — (?CName), (?C123Func) or (?Cn:Name) —
		/// which it stores as the callout function name. Stock PCRE2 (PCRE.NET) only accepts a numeric callout
		/// (?Cn) or a delimited string callout (?C'name'). This rewrites the AHK forms to the PCRE2 string form
		/// so existing scripts compile; the name then arrives as PcreCallout.String, which the callout handler
		/// already resolves to a function. Numeric callouts and already-delimited (?C'...') callouts are left
		/// untouched, and escapes, character classes and (?#...) comments are skipped so literal "(?C" is not
		/// rewritten. Note: the rewritten pattern is only what PCRE2 compiles; the script still sees the
		/// original needle as NeedleRegEx.
		/// </summary>
		internal static string TranslateCallouts(string pattern)
		{
			if (pattern is null || pattern.IndexOf("(?C", StringComparison.Ordinal) < 0)
				return pattern;

			var sb = new StringBuilder(pattern.Length + 8);
			int i = 0, len = pattern.Length;
			var inClass = false;

			while (i < len)
			{
				var c = pattern[i];

				if (c == '\\')//Escaped char: copy it and the next verbatim.
				{
					sb.Append(c);

					if (i + 1 < len)
						sb.Append(pattern[i + 1]);

					i += 2;
				}
				else if (inClass)
				{
					sb.Append(c);

					if (c == ']')
						inClass = false;

					i++;
				}
				else if (c == '[')
				{
					inClass = true;
					sb.Append(c);
					i++;
				}
				else if (c == '(' && i + 2 < len && pattern[i + 1] == '?' && pattern[i + 2] == '#')//(?#...) comment.
				{
					var j = i + 3;

					while (j < len && pattern[j] != ')')
						j += pattern[j] == '\\' && j + 1 < len ? 2 : 1;

					if (j < len)
						j++;

					sb.Append(pattern, i, j - i);
					i = j;
				}
				else if (c == '(' && i + 2 < len && pattern[i + 1] == '?' && pattern[i + 2] == 'C')//(?C...) callout.
				{
					i = AppendCallout(sb, pattern, i, len);
				}
				else
				{
					sb.Append(c);
					i++;
				}
			}

			return sb.ToString();
		}

		// Handles a single (?C...) starting at 'start'; appends the (possibly rewritten) callout and returns
		// the index just past it.
		private static int AppendCallout(StringBuilder sb, string pattern, int start, int len)
		{
			var p = start + 3;//Past "(?C".

			while (p < len && pattern[p] >= '0' && pattern[p] <= '9')
				p++;

			if (p < len && pattern[p] == ')')//(?C) or (?Cn): numeric callout, already valid PCRE2.
			{
				sb.Append(pattern, start, p + 1 - start);
				return p + 1;
			}

			if (p < len && Pcre2CalloutDelimiters.IndexOf(pattern[p]) >= 0)//Already a PCRE2 string callout.
			{
				var end = SkipPcre2String(pattern, p, len);

				if (end < 0)//Malformed; leave the rest for PCRE2 to reject.
				{
					sb.Append(pattern, start, len - start);
					return len;
				}

				sb.Append(pattern, start, end - start);
				return end;
			}

			//AHK unquoted name. A ':' right after the (optional) digits separates a number from the name
			//(the number is dropped, since PCRE2 string callouts are always number 0); otherwise the whole
			//tail after "(?C" is the name (e.g. (?C123Func) -> name "123Func").
			var nameStart = p < len && pattern[p] == ':' ? p + 1 : start + 3;
			var nameEnd = nameStart;

			while (nameEnd < len && pattern[nameEnd] != ')')
				nameEnd++;

			if (nameEnd >= len)//No closing ')'; leave the rest for PCRE2 to reject.
			{
				sb.Append(pattern, start, len - start);
				return len;
			}

			sb.Append("(?C'");

			foreach (var ch in pattern.AsSpan(nameStart, nameEnd - nameStart))
			{
				sb.Append(ch);

				if (ch == '\'')//Double single-quotes to escape one inside a '-delimited PCRE2 string.
					sb.Append('\'');
			}

			sb.Append("')");
			return nameEnd + 1;
		}

		// Given 'delimPos' at the opening delimiter of a PCRE2 string callout, returns the index just past the
		// closing ")", or -1 if malformed.
		private static int SkipPcre2String(string pattern, int delimPos, int len)
		{
			var open = pattern[delimPos];
			var close = open == '{' ? '}' : open;
			var q = delimPos + 1;

			while (q < len)
			{
				if (pattern[q] == close)
				{
					if (close != '}' && q + 1 < len && pattern[q + 1] == close)//Doubled delimiter = literal.
					{
						q += 2;
						continue;
					}

					q++;//Past the closing delimiter.
					return q < len && pattern[q] == ')' ? q + 1 : -1;
				}

				q++;
			}

			return -1;
		}
	}
}
