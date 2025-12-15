import 'package:awesome_calculator/shql/engine/cancellation_token.dart';
import 'package:awesome_calculator/shql/engine/engine.dart';
import 'package:awesome_calculator/shql/execution/set_variable_execution_node.dart';
import 'package:awesome_calculator/shql/execution/execution_node.dart';
import 'package:awesome_calculator/shql/execution/lazy_execution_node.dart';
import 'package:awesome_calculator/shql/execution/runtime.dart';
import 'package:awesome_calculator/shql/parser/parse_tree.dart';
import 'package:awesome_calculator/shql/tokenizer/token.dart';

class AssignmentExecutionNode extends LazyExecutionNode {
  AssignmentExecutionNode(
    super.node, {
    required super.thread,
    required super.scope,
  });

  @override
  Future<TickResult> doTick(
    Runtime runtime,
    CancellationToken? cancellationToken,
  ) async {
    if (_rhs == null) {
      var (rhs, e) = createRhs(runtime);
      if (e != null) {
        error = e;
        return TickResult.completed;
      }
      if (rhs == null) {
        return TickResult.completed;
      }
      _rhs = rhs;
      return TickResult.delegated;
    }

    if (_assignmentToGivenExecutionNode == null) {
      _assignmentToGivenExecutionNode = SetVariableExecutionNode(
        node.children[0],
        _rhs!.result,
        thread: thread,
        scope: scope,
      );
      return TickResult.delegated;
    }
    result = _assignmentToGivenExecutionNode!.result;
    error ??= _assignmentToGivenExecutionNode!.error;
    return TickResult.completed;
  }

  (ExecutionNode?, String?) createRhs(Runtime runtime) {
    // Verify that node has exactly two children
    if (node.children.length != 2) {
      return (
        null,
        "Assignment operator requires exactly two operands, ${node.children.length} given.",
      );
    }

    // Check if lhs has an argument which is a tuple (for function definition)
    // Eg: f(x) := x + 1 meaning  Symbols.tuple
    // If it is a function definition, all arguments must be identifiers without any children themselves
    var identifierChild = node.children[0];
    var childrenCount = identifierChild.children.length;
    var identifier = identifierChild.qualifier!;
    var name = runtime.identifiers.constants[identifier];
    if (childrenCount > 1) {
      return (
        null,
        "Identifier $name can have at most one child, ${node.children.length} given.",
      );
    }

    if (childrenCount == 1) {
      var child = identifierChild.children[0];
      if (child.symbol == Symbols.tuple) {
        if (defineUserFunction(name, child, runtime, identifier)) {
          return (null, null);
        } else {
          return (null, "Cannot create user function for identifier $name.");
        }
      }
      if (child.symbol != Symbols.list) {
        return (null, "Invalid child for identifier $name in assignment.");
      }
    }

    return (Engine.createExecutionNode(node.children[1], thread, scope)!, null);
  }

  bool defineUserFunction(
    String name,
    ParseTree child,
    Runtime runtime,
    int identifier,
  ) {
    var arguments = child.children;
    List<int> argumentIdentifiers = [];
    for (var arg in arguments) {
      if (arg.symbol != Symbols.identifier) {
        error = "All arguments in function definition must be identifiers.";
        return true;
      }
      if (arg.children.isNotEmpty) {
        error = "Arguments in function definition cannot have children.";
        return true;
      }
      argumentIdentifiers.add(arg.qualifier!);
    }
    var userFunction = UserFunction(
      name: name,
      argumentIdentifiers: argumentIdentifiers,
      scope: scope,
      body: node.children[1],
    );
    scope.members.defineUserFunction(identifier, userFunction);
    result = userFunction;
    return true;
  }

  SetVariableExecutionNode? _assignmentToGivenExecutionNode;
  ExecutionNode? _rhs;
}
