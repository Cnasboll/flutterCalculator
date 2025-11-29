import 'package:awesome_calculator/shql/engine/engine.dart';
import 'package:awesome_calculator/shql/execution/execution_node.dart';
import 'package:awesome_calculator/shql/execution/lazy_execution_node.dart';
import 'package:awesome_calculator/shql/parser/constants_set.dart';

abstract class LazyParentExecutionNode extends LazyExecutionNode {
  LazyParentExecutionNode(super.node);

  @override
  bool doTick(ConstantsSet constantsSet) {
    if (children == null) {
      List<ExecutionNode> r = [];
      for (var child in node.children) {
        var childRuntime = Engine.createExecutionNode(child);
        if (childRuntime == null) {
          error = 'Failed to create runtime for child node.';
          return true;
        }

        r.add(childRuntime);
      }
      children = r;
    }

    for (var child in children!) {
      if (!child.tick(constantsSet)) {
        return false;
      }
    }
    onChildrenComplete();
    return true;
  }

  void onChildrenComplete();

  List<ExecutionNode>? children;
}
