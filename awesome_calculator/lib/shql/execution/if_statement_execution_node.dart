import 'package:awesome_calculator/shql/engine/cancellation_token.dart';
import 'package:awesome_calculator/shql/engine/engine.dart';
import 'package:awesome_calculator/shql/execution/execution_node.dart';
import 'package:awesome_calculator/shql/execution/lazy_execution_node.dart';
import 'package:awesome_calculator/shql/execution/runtime.dart';

class IfStatementExecutionNode extends LazyExecutionNode {
  IfStatementExecutionNode(super.node, {required super.scope});

  ExecutionNode? _conditionNode;
  ExecutionNode? _branchNode;

  @override
  Future<bool> doTick(
    Runtime runtime,
    CancellationToken? cancellationToken,
  ) async {
    if (_branchNode != null) {
      if (!await tickChild(_branchNode!, runtime, cancellationToken)) {
        return false;
      }
      if (await runtime.check(cancellationToken)) {
        return true;
      }
      return true;
    }

    _conditionNode ??= Engine.createExecutionNode(node.children[0], scope);
    if (!await tickChild(_conditionNode!, runtime, cancellationToken)) {
      return false;
    }
    if (await runtime.check(cancellationToken)) {
      return true;
    }

    var conditionResult = _conditionNode!.result;
    if (conditionResult == true) {
      _branchNode = Engine.createExecutionNode(node.children[1], scope);
    } else if (node.children.length > 2) {
      // Else branch
      _branchNode = Engine.createExecutionNode(node.children[2], scope);
    } else {
      result = false;
      return true;
    }
    if (!await tickChild(_branchNode!, runtime, cancellationToken)) {
      return false;
    }
    return true;
  }
}
