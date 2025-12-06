import 'package:awesome_calculator/shql/engine/cancellation_token.dart';
import 'package:awesome_calculator/shql/engine/engine.dart';
import 'package:awesome_calculator/shql/execution/execution_node.dart';
import 'package:awesome_calculator/shql/execution/lazy_execution_node.dart';
import 'package:awesome_calculator/shql/execution/runtime.dart';

class ReturnStatementExecutionNode extends LazyExecutionNode {
  ReturnStatementExecutionNode(super.node);

  @override
  Future<bool> doTick(
    Runtime runtime,
    CancellationToken? cancellationToken,
  ) async {
    var returnTarget = runtime.currentReturnTarget;
    if (returnTarget == null) {
      error = 'Return statement used outside of a function.';
      return true;
    }
    if (node.children.isNotEmpty && _returnValueNode == null) {
      if (node.children.length > 1) {
        error = 'Return statement can have at most one child.';
        return true;
      }

      _returnValueNode = Engine.createExecutionNode(node.children[0]);
      if (_returnValueNode == null) {
        error = 'Failed to create execution node for return value.';
        return true;
      }
    }

    if (_returnValueNode != null) {
      if (!await tickChild(_returnValueNode!, runtime, cancellationToken)) {
        if (await runtime.check(cancellationToken)) {
          return true;
        }
        returnTarget.returnValue(_returnValueNode!.result);
        return true;
      }
    }

    returnTarget.returnNothing();
    return true;
  }

  ExecutionNode? _returnValueNode;
}
