import 'package:awesome_calculator/shql/execution/null_aware_unary_node.dart';

class NotExecutionNode extends NullAwareUnaryNode {
  NotExecutionNode(super.operand);

  @override
  Future<dynamic> evaluate(dynamic operandResult) async =>
      operandResult is bool ? !operandResult : operandResult == 0;
}
