import 'package:awesome_calculator/shql/execution/lazy_parent_execution_node.dart';

class MapLiteralNode extends LazyParentExecutionNode {
  MapLiteralNode(super.node, {required super.scope});
  @override
  void onChildrenComplete() {
    result = children!.map((c) => c.result).toList();
  }
}
