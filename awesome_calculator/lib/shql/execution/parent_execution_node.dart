import 'package:awesome_calculator/shql/execution/execution_node.dart';
import 'package:awesome_calculator/shql/parser/constants_set.dart';

abstract class ParentExecutionNode extends ExecutionNode {
  ParentExecutionNode(this.children);

  @override
  bool doTick(ConstantsSet constantsSet) {
    for (int i = 0; i < children.length; i++) {
      var child = children[i];
      if (!child.tick(constantsSet)) {
        return false;
      }
      if (!onChildComplete(i, child)) {
        return false;
      }
    }
    onChildrenComplete(constantsSet);
    return true;
  }

  bool onChildComplete(int index, ExecutionNode child) {
    return true;
  }

  void onChildrenComplete(ConstantsSet constantsSet) {}

  List<ExecutionNode> children;
}
