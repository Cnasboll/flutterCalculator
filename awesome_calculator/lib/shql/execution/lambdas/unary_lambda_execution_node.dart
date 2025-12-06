import 'package:awesome_calculator/shql/execution/null_aware_unary_node.dart';

class UnaryLambdaExecutionNode extends NullAwareUnaryNode {
  final dynamic Function(dynamic) unaryFunction;

  UnaryLambdaExecutionNode(this.unaryFunction, super.operand);

  @override
  Future<dynamic> evaluate(dynamic operandResult) async =>
      await unaryFunction(operandResult);
}
