import 'package:awesome_calculator/shql/execution/null_aware_unary_node.dart';

class UnaryLambdaExecutionNode extends NullAwareUnaryNode {
  final dynamic Function(dynamic) unaryFunction;

  UnaryLambdaExecutionNode(this.unaryFunction, super.operand);

  @override
  dynamic evaluate(dynamic operandResult) => unaryFunction(operandResult);
}
