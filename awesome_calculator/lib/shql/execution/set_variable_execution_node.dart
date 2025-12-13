import 'package:awesome_calculator/shql/engine/cancellation_token.dart';
import 'package:awesome_calculator/shql/engine/engine.dart';
import 'package:awesome_calculator/shql/execution/execution_node.dart';
import 'package:awesome_calculator/shql/execution/lazy_execution_node.dart';
import 'package:awesome_calculator/shql/execution/runtime.dart';
import 'package:awesome_calculator/shql/tokenizer/token.dart';

class SetVariableExecutionNode extends LazyExecutionNode {
  SetVariableExecutionNode(
    super.node,
    this.rhsValue, {
    required super.thread,
    required super.scope,
  });

  @override
  Future<TickResult> doTick(
    Runtime runtime,
    CancellationToken? cancellationToken,
  ) async {
    // Verify that first child is an identifier
    if (node.symbol != Symbols.identifier) {
      error = "Left-hand side of assignment must be an identifier.";
      return TickResult.completed;
    }

    if (_indexerNode == null) {
      var (indexerNode, e) = tryCreateIndexerExecutionNode(runtime);
      if (e != null) {
        error = e;
        return TickResult.completed;
      }
      if (indexerNode != null) {
        _indexerNode = indexerNode;
        return TickResult.delegated;
      }
    }

    var identifier = node.qualifier!;

    var (target, containingScope, isConstant) = scope.resolveIdentifier(
      identifier,
    );

    if (isConstant) {
      error = "Cannot assign to constant.";
      return TickResult.completed;
    }

    if (_indexerNode != null) {
      // Assignment to indexer
      target[_indexerNode!.result] = rhsValue;
      return TickResult.completed;
    }

    if (rhsValue is UserFunction) {
      var (containingScope, _, error) = scope.defineUserFunction(
        identifier,
        rhsValue,
      );
      if (error != null) {
        this.error = error;
        return TickResult.completed;
      }
    } else {
      var (containingScope, error) = scope.setVariable(identifier, rhsValue);
      if (error != null) {
        this.error = error;
        return TickResult.completed;
      }
    }

    result = rhsValue;
    return TickResult.completed;
  }

  (ExecutionNode?, String?) tryCreateIndexerExecutionNode(Runtime runtime) {
    // Check if lhs has an argument which is a single element list (for indexer)
    // Eg: a[0] := 5 meaning Symbols.list
    //var identifierChild = node.children[0];
    var childrenCount = node.children.length;
    var identifier = node.qualifier!;
    var name = runtime.identifiers.constants[identifier];
    if (childrenCount > 1) {
      return (
        null,
        "Identifier $name can have at most one child, ${node.children.length} given.",
      );
    }

    if (childrenCount == 1) {
      var child = node.children[0];
      if (child.symbol == Symbols.list && child.children.length == 1) {
        return (
          Engine.createExecutionNode(child.children[0], thread, scope),
          null,
        );
      }
    }
    return (null, null);
  }

  ExecutionNode? _indexerNode;
  final dynamic rhsValue;
}
