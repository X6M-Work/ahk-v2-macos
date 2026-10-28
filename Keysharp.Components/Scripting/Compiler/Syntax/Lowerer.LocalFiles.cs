using Keysharp.Parsing.Syntax;
using Microsoft.CodeAnalysis.CSharp;
using Microsoft.CodeAnalysis.CSharp.Syntax;

namespace Keysharp.Compilation.Syntax
{
	internal sealed partial class Lowerer
	{
		private HashSet<CallExpr> _localFileCalls;
		private string _localFileScopeName;
		private static readonly HashSet<string> LocalFileMethods = new(AhkIdentifierComparer.Instance)
		{
			"Close", "Flush", "Read", "ReadLine", "Write", "WriteLine", "Seek", "RawRead", "RawWrite",
			"ReadChar", "ReadUChar", "ReadShort", "ReadUShort", "ReadInt", "ReadUInt", "ReadInt64", "ReadFloat", "ReadDouble",
			"WriteChar", "WriteUChar", "WriteShort", "WriteUShort", "WriteInt", "WriteUInt", "WriteInt64", "WriteFloat", "WriteDouble"
		};

		private HashSet<CallExpr> FindLocalFiles(Block block, FunctionScope scope)
		{
			if (block == null || scope.HasDeref || scope.HasRegex || scope.HasListVars)
				return null;
			if (!AnyNode(block, node => node is CallExpr call && NativeCallTarget(call.Callee)?.Builtin is { Name: "FileOpen", DeclaringType: var type }
				&& type == typeof(Keysharp.Builtins.Files)))
				return null;
			var nodes = new List<(Node Node, Node Parent)>();
			var parents = new Dictionary<Node, Node>();
			void Visit(Node node, Node parent)
			{
				if (node == null) return;
				nodes.Add((node, parent));
				parents[node] = parent;
				foreach (var child in AstChildren.Of(node)) Visit(child, node);
			}
			Visit(block, null);
			if (nodes.Any(pair => pair.Node is FunctionDecl or FatArrowExpr or ClassDecl or HotkeyDef or HotstringDef or DerefExpr or CSharpDirective or GotoStmt))
				return null;
			var aliases = new HashSet<string>(AhkIdentifierComparer.Instance);
			var calls = new HashSet<CallExpr>();
			bool Local(NameExpr name) => scope.Find(name.Name) is { Storage: VarStorage.Local, Owner: var owner } && owner == scope;
			foreach (var (node, _) in nodes)
				if (node is AssignExpr { Op: ":=", Target: NameExpr name, Value: CallExpr call }
					&& Local(name) && NativeCallTarget(call.Callee)?.Builtin is { Name: "FileOpen", DeclaringType: var type }
					&& type == typeof(Keysharp.Builtins.Files))
				{
					aliases.Add(name.Name);
					calls.Add(call);
				}
			if (calls.Count == 0) return null;
			bool changed;
			do
			{
				changed = false;
				foreach (var (node, _) in nodes)
					if (node is AssignExpr { Op: ":=", Target: NameExpr target, Value: NameExpr source }
						&& aliases.Contains(source.Name) && Local(target))
						changed |= aliases.Add(target.Name);
			} while (changed);
			if (nodes.Any(pair => pair.Node is ForStmt loop && loop.Vars.Any(aliases.Contains)
				|| pair.Node is TryStmt attempt && attempt.Catches.Any(handler => handler.Var != null && aliases.Contains(handler.Var))))
				return null;
			foreach (var alias in aliases)
			{
				if (scope.Params?.Any(parameter => AhkIdentifierComparer.Instance.Equals(parameter.Name, alias)) == true)
					return null;
				var writes = nodes.Where(pair => pair.Node is AssignExpr { Target: NameExpr name } && AhkIdentifierComparer.Instance.Equals(name.Name, alias)).ToArray();
				if (writes.Length != 1)
					return null;
				for (var parent = writes[0].Parent; parent != null; parent = parents[parent])
					if (parent is WhileStmt or LoopStmt or ForStmt or SpecialLoopStmt)
						return null;
			}
			foreach (var (node, parent) in nodes)
				if (node is NameExpr name && aliases.Contains(name.Name))
				{
					if (parent is AssignExpr { Op: ":=", Target: NameExpr target } assignment
						&& (assignment.Target == node || assignment.Value == node && Local(target)))
						continue;
					if (parent is MemberExpr member && member.Target == node && LocalFileMethods.Contains(member.Name)
						&& parents[member] is CallExpr call && call.Callee == member)
						continue;
					return null;
				}
			return calls;
		}

		private void WrapLocalFiles(List<StatementSyntax> body, int start, int end)
		{
			var inner = body.GetRange(start, end - start);
			body.RemoveRange(start, end - start);
			body.Insert(start, SyntaxFactory.UsingStatement(null,
				Assign(Id(_localFileScopeName), New("Keysharp.Runtime.LocalFileScope")), SyntaxFactory.Block(inner)));
			body.Insert(0, LocalDecl(Ty("Keysharp.Runtime.LocalFileScope"), _localFileScopeName, Null));
		}
	}
}
