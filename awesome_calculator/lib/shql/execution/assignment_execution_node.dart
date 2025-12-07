import 'package:awesome_calculator/shql/engine/cancellation_token.dart';
import 'package:awesome_calculator/shql/engine/engine.dart';
import 'package:awesome_calculator/shql/execution/execution_node.dart';
import 'package:awesome_calculator/shql/execution/lazy_execution_node.dart';
import 'package:awesome_calculator/shql/execution/runtime.dart';
import 'package:awesome_calculator/shql/parser/parse_tree.dart';
import 'package:awesome_calculator/shql/tokenizer/token.dart';

class AssignmentExecutionNode extends LazyExecutionNode {
  AssignmentExecutionNode(super.node);

  @override
  Future<bool> doTick(
    Runtime runtime,
    CancellationToken? cancellationToken,
  ) async {
    if (await runtime.check(cancellationToken)) {
      return true;
    }

    if (_rhs == null) {
      if (_indexerNode == null) {
        var (indexerNode, e) = tryCreateIndexerExecutionNode(runtime);
        if (e != null) {
          error = e;
          return true;
        }
        _indexerNode = indexerNode;
      }

      if (_indexerNode != null && _rhs == null) {
        if (!await tickChild(_indexerNode!, runtime, cancellationToken)) {
          return false;
        }
      }

      if (await runtime.check(cancellationToken)) {
        return true;
      }

      if (_rhs == null) {
        var (rhs, e) = createRhs(runtime);
        if (e != null) {
          error = e;
          return true;
        }
        if (rhs == null) {
          return true;
        }
        _rhs = rhs;
      }
    }

    if (!await tickChild(_rhs!, runtime, cancellationToken)) {
      return false;
    }

    if (await runtime.check(cancellationToken)) {
      return true;
    }

    if (_indexerNode != null) {
      // Assignment to indexer
      var identifier = node.children[0].qualifier!;
      var (target, isValue, _) = runtime.resolveIdentifier(identifier);
      if (!isValue) {
        error = "Cannot assign to non-variable identifier.";
        return true;
      }
      target[_indexerNode!.result] = _rhs!.result;

      if (await runtime.check(cancellationToken)) {
        return true;
      }

      return true;
    }

    var identifier = node.children[0].qualifier!;

    if (_rhs!.result is UserFunction) {
      runtime.setUserFunction(identifier, _rhs!.result);
      return true;
    } else {
      runtime.setVariable(identifier, _rhs!.result);
    }

    if (await runtime.check(cancellationToken)) {
      return true;
    }

    return true;
  }

  (ExecutionNode?, String?) tryCreateIndexerExecutionNode(Runtime runtime) {
    // Verify that first child is an identifier
    if (node.children[0].symbol != Symbols.identifier) {
      return (null, "Left-hand side of assignment must be an identifier.");
    }

    // Check if lhs has an argument which is a single element list (for indexer)
    // Eg: a[0] := 5 meaning Symbols.list
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
      if (child.symbol == Symbols.list && child.children.length == 1) {
        return (Engine.createExecutionNode(child.children[0]), null);
      }
    }
    return (null, null);
  }

  (ExecutionNode?, String?) createRhs(Runtime runtime) {
    // Verify that node has exactly two children
    if (node.children.length != 2) {
      return (
        null,
        "Assignment operator requires exactly two operands, ${node.children.length} given.",
      );
    }

    // Verify that first child is an identifier
    if (node.children[0].symbol != Symbols.identifier) {
      return (null, "Left-hand side of assignment must be an identifier.");
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

    return (Engine.createExecutionNode(node.children[1])!, null);
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
      body: node.children[1],
    );
    runtime.setUserFunction(identifier, userFunction);
    result = userFunction;
    return true;
  }

  ExecutionNode? _indexerNode;
  ExecutionNode? _rhs;
}
