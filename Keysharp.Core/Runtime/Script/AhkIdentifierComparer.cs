namespace Keysharp.Runtime
{
	/// <summary>AHK names fold ASCII case; every other UTF-16 code unit remains distinct.</summary>
	[PublicHiddenFromUser]
	public sealed class AhkIdentifierComparer : StringComparer, IAlternateEqualityComparer<ReadOnlySpan<char>, string>
	{
		public static readonly AhkIdentifierComparer Instance = new();
		private AhkIdentifierComparer() { }

		private static char Fold(char value) => value is >= 'A' and <= 'Z' ? (char)(value + ('a' - 'A')) : value;

		public override int Compare(string left, string right)
		{
			if (ReferenceEquals(left, right)) return 0;
			if (left == null) return -1;
			if (right == null) return 1;

			for (var i = 0; i < Math.Min(left.Length, right.Length); i++)
			{
				var difference = Fold(left[i]) - Fold(right[i]);
				if (difference != 0) return difference;
			}

			return left.Length.CompareTo(right.Length);
		}

		public override bool Equals(string left, string right)
		{
			if (ReferenceEquals(left, right)) return true;
			return left != null && right != null && Equals(left.AsSpan(), right.AsSpan());
		}

		public bool Equals(ReadOnlySpan<char> left, ReadOnlySpan<char> right)
		{
			if (left.Length != right.Length) return false;

			for (var i = 0; i < left.Length; i++)
				if (Fold(left[i]) != Fold(right[i])) return false;

			return true;
		}

		public override int GetHashCode(string value)
		{
			ArgumentNullException.ThrowIfNull(value);
			return GetHashCode(value.AsSpan());
		}

		public int GetHashCode(ReadOnlySpan<char> value)
		{
			var hash = new HashCode();

			foreach (var character in value)
				hash.Add(Fold(character));

			return hash.ToHashCode();
		}

		bool IAlternateEqualityComparer<ReadOnlySpan<char>, string>.Equals(ReadOnlySpan<char> alternate, string other) =>
			other != null && Equals(alternate, other.AsSpan());

		string IAlternateEqualityComparer<ReadOnlySpan<char>, string>.Create(ReadOnlySpan<char> value) => value.ToString();
	}
}
