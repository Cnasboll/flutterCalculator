import 'package:awesome_calculator/shql/engine/cancellation_token.dart';
import 'package:awesome_calculator/shql/execution/execution_node.dart';
import 'package:awesome_calculator/shql/execution/runtime.dart';

abstract class ParentExecutionNode extends ExecutionNode {
  ParentExecutionNode(this.children, {required super.scope});

  @override
  Future<bool> doTick(
    Runtime runtime,
    CancellationToken? cancellationToken,
  ) async {
    if (await runtime.check(cancellationToken)) {
      return true;
    }
    for (int i = 0; i < children.length; i++) {
      var child = children[i];
      if (!await tickChild(child, runtime, cancellationToken)) {
        return false;
      }
      if (await runtime.check(cancellationToken)) {
        return true;
      }
      if (!onChildComplete(i, child)) {
        return false;
      }
    }
    await onChildrenComplete(runtime);
    return true;
  }

  bool onChildComplete(int index, ExecutionNode child) {
    return true;
  }

  Future<void> onChildrenComplete(Runtime runtime) async {}

  List<ExecutionNode> children;
}
