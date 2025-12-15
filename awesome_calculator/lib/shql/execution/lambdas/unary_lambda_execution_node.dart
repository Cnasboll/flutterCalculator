import 'package:awesome_calculator/shql/execution/null_aware_unary_node.dart';

class UnaryLambdaExecutionNode extends NullAwareUnaryNode {
  final dynamic Function(dynamic) unaryFunction;

  UnaryLambdaExecutionNode(
    this.unaryFunction,
    super.operand, {
    required super.thread,
    required super.scope,
  });

  @override
  Future<dynamic> applyNotNull() async => await unaryFunction(operandResult);
}
