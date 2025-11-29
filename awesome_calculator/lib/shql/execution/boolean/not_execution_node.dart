import 'package:awesome_calculator/shql/execution/null_aware_unary_node.dart';

class NotExecutionNode extends NullAwareUnaryNode {
  NotExecutionNode(super.operand);

  @override
  dynamic evaluate(dynamic operandResult) =>
      operandResult is bool ? !operandResult : operandResult == 0;
}
