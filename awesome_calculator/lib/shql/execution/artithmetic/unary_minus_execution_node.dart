import 'package:awesome_calculator/shql/execution/null_aware_unary_node.dart';

class UnaryMinusExecutionNode extends NullAwareUnaryNode {
  UnaryMinusExecutionNode(super.operand);

  @override
  dynamic evaluate(dynamic operandResult) => -operandResult;
}
