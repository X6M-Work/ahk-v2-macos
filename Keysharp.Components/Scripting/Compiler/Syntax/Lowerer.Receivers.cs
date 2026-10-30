using System.Collections.Generic;
using System.Linq;
using Microsoft.CodeAnalysis.CSharp;
using Microsoft.CodeAnalysis.CSharp.Syntax;
using Keysharp.Parsing.Syntax;

namespace Keysharp.Compilation.Syntax;

internal sealed partial class Lowerer
{
	private static bool NamedReceiver(Expr receiver) => receiver is NameExpr
		|| receiver is GroupExpr group && NamedReceiver(group.Inner);
	private ExpressionSyntax ReceiverValue(Expr receiver, List<ExpressionSyntax> setup)
	{
		var value = LowerExpr(receiver);
		if (NakedVariable(receiver) is { } name)
		{
			if (!NamedReceiver(receiver)) setup.Add(value);
			return NamedReceiver(receiver) ? value : LowerExpr(name);
		}
		var temp = Id(NewTemp());
		setup.Add(Assign(temp, value));
		return temp;
	}

	private ExpressionSyntax LateReceiver(Expr receiver, ExpressionSyntax operation, int argumentStart, bool packed = false, Expr dynamicName = null, List<Argument> sourceArguments = null)
	{
		var call = (InvocationExpressionSyntax)operation;
		var arguments = call.ArgumentList.Arguments;
		var variable = NakedVariable(receiver);
		var deferred = !packed && sourceArguments?.Count == arguments.Count - argumentStart && sourceArguments.All(a => !a.IsNamed);
		if (variable == null && NakedVariable(dynamicName) == null
			&& !(deferred && sourceArguments.Any(a => NakedVariable(a.Value) != null))) return operation;
		var setup = new List<ExpressionSyntax>();
		void Capture(int index, bool array)
		{
			var temp = Id(NewTemp());
			var value = arguments[index].Expression;
			setup.Add(Assign(temp, array ? SyntaxFactory.CastExpression(ObjArrayType, value) : value));
			arguments = arguments.Replace(arguments[index], arguments[index].WithExpression(
				array ? SyntaxFactory.CastExpression(ObjArrayType, temp) : temp));
		}
		void ResolveVariable(int index, Expr source, NameExpr name)
		{
			if (NamedReceiver(source)) return;
			setup.Add(arguments[index].Expression);
			arguments = arguments.Replace(arguments[index], arguments[index].WithExpression(LowerExpr(name)));
		}
		if (variable == null) Capture(0, false);
		else ResolveVariable(0, receiver, variable);
		// Computed names run before arguments; variable names are resolved with the receiver after them.
		if (dynamicName != null)
		{
			if (NakedVariable(dynamicName) is { } name) ResolveVariable(1, dynamicName, name);
			else Capture(1, false);
		}
		for (var i = argumentStart; i < arguments.Count; i++)
		{
			var source = deferred ? sourceArguments[i - argumentStart].Value : null;
			if (NakedVariable(source) is { } name) ResolveVariable(i, source, name);
			else Capture(i, packed);
		}
		if (setup.Count == 0) return operation;
		setup.Add(call.WithArgumentList(call.ArgumentList.WithArguments(arguments)));
		return Op("MultiStatement", setup.ToArray());
	}

	private ExpressionSyntax LateSpreadParams(List<Argument> args, ExpressionSyntax trailing)
	{
		var setup = new List<ExpressionSyntax>();
		var values = args.Select(a => a.Value == null ? Null : ReceiverValue(a.Value, setup)).ToArray();
		if (trailing != null)
		{
			var value = Id(NewTemp());
			setup.Add(Assign(value, trailing));
			trailing = value;
		}
		var elements = new List<CollectionElementSyntax>();
		for (var i = 0; i < args.Count; i++)
		{
			if (args[i].Spread)
			{
				var expanded = Id(NewTemp());
				setup.Add(Assign(expanded, Op("FlattenValues", values[i])));
				elements.Add(SyntaxFactory.SpreadElement(SyntaxFactory.CastExpression(ObjArrayType, expanded)));
			}
			else elements.Add(SyntaxFactory.ExpressionElement(values[i]));
		}
		if (trailing != null) elements.Add(SyntaxFactory.ExpressionElement(trailing));
		setup.Add(SyntaxFactory.CastExpression(ObjArrayType,
			SyntaxFactory.CollectionExpression(SyntaxFactory.SeparatedList(elements))));
		return SyntaxFactory.CastExpression(ObjArrayType, Op("MultiStatement", setup.ToArray()));
	}
}
