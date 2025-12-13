import 'package:awesome_calculator/shql/execution/null_aware_unary_node.dart';

class IndexToExecutionNode extends NullAwareUnaryNode {
  IndexToExecutionNode(
    super.node,
    this.indexable, {
    required super.thread,
    required super.scope,
  });

  dynamic indexable;

  @override
  Future<dynamic> applyNotNull() async => indexable[operandResult];
}
