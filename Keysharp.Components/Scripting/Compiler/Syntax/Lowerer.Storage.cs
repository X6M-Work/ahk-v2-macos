using Microsoft.CodeAnalysis.CSharp.Syntax;
using Microsoft.CodeAnalysis.CSharp;
using Keysharp.Internals.ExtensionMethods;
using Keysharp.Parsing.Syntax;

namespace Keysharp.Compilation.Syntax
{
	internal sealed partial class Lowerer
	{
		private int _boxCounter;
		private static ExpressionSyntax NewBox(ExpressionSyntax value) => Inv(Access("Keysharp.Runtime.Lifetime.Box"), value);

		private sealed class LocalStorage
		{
			public string Box;
			private ExpressionSyntax value, boxedValue;
			public ExpressionSyntax Read(Lowerer lowerer, string name) => Box != null
				? boxedValue ??= Member(Id(Box), "__Value")
				: value ??= lowerer.Unsettled(Id(NameMangler.Escape(name)), () => Box != null, _ => Member(Id(Box), "__Value"));
		}

		private LocalStorage Storage(ScopeVar variable) => variable.Owner.Variables.GetOrAdd(variable.Key);
		private ExpressionSyntax LocalValue(ScopeVar variable) => Storage(variable).Read(this, variable.Key);
		private ScopeVar Receiver() => _scope.Find("this") is { Storage: not VarStorage.None } parameter
			? parameter : new("this", VarStorage.Local, _scope.Root);

		private static ExpressionSyntax EscapingValue(ExpressionSyntax value) => Inv(Access("Keysharp.Runtime.Lifetime.Escape"), value);
		private static ExpressionSyntax BorrowValue(ExpressionSyntax value) => Inv(Access("Keysharp.Runtime.Lifetime.Borrow"), value);
		private static ExpressionSyntax ReturnValue(ExpressionSyntax value) => Inv(Access("Keysharp.Runtime.Lifetime.Return"), value);
		private static ExpressionSyntax ReplaceValue(ExpressionSyntax target, ExpressionSyntax value) =>
			SyntaxFactory.InvocationExpression(Access("Keysharp.Runtime.Lifetime.Replace"), SyntaxFactory.ArgumentList(
				SyntaxFactory.SeparatedList(new[] { Arg(target).WithRefKindKeyword(SyntaxFactory.Token(SyntaxKind.RefKeyword)), Arg(value) })));

		private ExpressionSyntax WriteVariable(ScopeVar variable, ExpressionSyntax target, ExpressionSyntax value)
		{
			if (variable.Storage != VarStorage.Local) return ReplaceValue(target, value);
			var storage = Storage(variable);
			ExpressionSyntax BoxedWrite(ExpressionSyntax input) => Inv(Access("Keysharp.Runtime.Lifetime.Replace"), Id(storage.Box), input);
			return storage.Box != null ? BoxedWrite(value)
				: Unsettled(ReplaceValue(target, value), () => storage.Box != null, node =>
					BoxedWrite(((InvocationExpressionSyntax)node).ArgumentList.Arguments[1].Expression));
		}

		private ExpressionSyntax LowerOwnedValue(Expr value) => value switch
		{
			NameExpr name => LowerName(name, name.Name, owned: true),
			GroupExpr group => SyntaxFactory.ParenthesizedExpression(LowerOwnedValue(group.Inner)),
			AssignExpr assignment => LowerAssign(assignment),
			CallExpr call => LowerCall(call, statement: false),
			_ => LowerExpr(value)
		};

		private ExpressionSyntax LocalBox(ScopeVar variable)
		{
			var storage = Storage(variable);
			storage.Box ??= "KS_box" + ++_boxCounter;
			return Id(storage.Box);
		}

		private StatementSyntax DeclareVariable(FunctionScope scope, string name, ExpressionSyntax value)
		{
			var variable = scope.Find(name);
			var storage = Storage(variable);
			if (storage.Box != null)
				return LocalDeclVar(storage.Box, NewBox(value));
			var declaration = LocalDecl(ObjType, NameMangler.Escape(variable.Key), value);
			return Unsettled(declaration, () => storage.Box != null, node => LocalDeclVar(storage.Box,
				NewBox(((LocalDeclarationStatementSyntax)node).Declaration.Variables[0].Initializer.Value)));
		}

		private void InitializeParameters(List<StatementSyntax> body, IEnumerable<ScopeVar> parameters)
		{
			foreach (var parameter in parameters)
			{
				var storage = Storage(parameter);
				var name = Id(NameMangler.Escape(parameter.Key));
				body.Insert(0, storage.Box != null ? LocalDeclVar(storage.Box, NewBox(name))
					: Unsettled(CallStmt("Keysharp.Runtime.Lifetime.Retain", name), () => storage.Box != null,
						_ => LocalDeclVar(storage.Box, NewBox(name))));
			}
		}

		private ExpressionSyntax ScopeRoot(ScopeVar variable)
		{
			var storage = Storage(variable);
			return storage.Box != null ? Id(storage.Box)
				: Unsettled(Id(NameMangler.Escape(variable.Key)), () => storage.Box != null, _ => Id(storage.Box));
		}
	}
}
