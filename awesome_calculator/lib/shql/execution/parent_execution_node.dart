import 'package:awesome_calculator/shql/execution/execution_node.dart';
import 'package:awesome_calculator/shql/execution/runtime.dart';

abstract class ParentExecutionNode extends ExecutionNode {
  ParentExecutionNode(this.children);

  @override
  bool doTick(Runtime runtime) {
    for (int i = 0; i < children.length; i++) {
      var child = children[i];
      if (!child.tick(runtime)) {
        return false;
      }
      if (!onChildComplete(i, child)) {
        return false;
      }
    }
    onChildrenComplete(runtime);
    return true;
  }

  bool onChildComplete(int index, ExecutionNode child) {
    return true;
  }

  void onChildrenComplete(Runtime runtime) {}

  List<ExecutionNode> children;
}
