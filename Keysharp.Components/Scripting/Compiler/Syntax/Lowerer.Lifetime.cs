using Microsoft.CodeAnalysis.CSharp;
using Microsoft.CodeAnalysis.CSharp.Syntax;

namespace Keysharp.Compilation.Syntax
{
	internal sealed partial class Lowerer
	{
		private static StatementSyntax ExpressionLifetime(StatementSyntax statement) => statement == null ? null
			: SyntaxFactory.UsingStatement(null, Inv(Access("Keysharp.Runtime.Lifetime.BeginExpression")), AsBlock(statement));

		private static ExpressionSyntax EvaluateLifetime(ExpressionSyntax value) => value is LiteralExpressionSyntax ? value
			: Inv(Access("Keysharp.Runtime.Lifetime.Evaluate"), SyntaxFactory.ParenthesizedLambdaExpression(value));
	}
}
