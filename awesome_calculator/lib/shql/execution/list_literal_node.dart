import 'package:awesome_calculator/shql/execution/lazy_parent_execution_node.dart';

class ListLiteralNode extends LazyParentExecutionNode {
  ListLiteralNode(super.node);
  @override
  void onChildrenComplete() {
    result = children!.map((c) => c.result).toList();
  }
}
