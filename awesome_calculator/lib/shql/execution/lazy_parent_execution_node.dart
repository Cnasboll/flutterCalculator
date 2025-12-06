import 'package:awesome_calculator/shql/engine/engine.dart';
import 'package:awesome_calculator/shql/execution/execution_node.dart';
import 'package:awesome_calculator/shql/execution/lazy_execution_node.dart';
import 'package:awesome_calculator/shql/execution/runtime.dart';

abstract class LazyParentExecutionNode extends LazyExecutionNode {
  LazyParentExecutionNode(super.node);

  @override
  Future<bool> doTick(Runtime runtime) async {
    if (children == null) {
      List<ExecutionNode> r = [];
      for (var child in node.children) {
        var childRuntime = Engine.createExecutionNode(child);
        if (childRuntime == null) {
          error = 'Failed to create execution node for child node.';
          return true;
        }

        r.add(childRuntime);
      }
      children = r;
    }

    while (_currentChildIndex < children!.length) {
      var child = children![_currentChildIndex];
      if (!await tickChild(child, runtime)) {
        return false;
      }
      ++_currentChildIndex;
    }
    onChildrenComplete();
    return true;
  }

  void onChildrenComplete();

  List<ExecutionNode>? children;
  int _currentChildIndex = 0;
}
