import 'package:awesome_calculator/shql/execution/null_aware_binary_node.dart';

class BinaryLambdaExecutionNode extends NullAwareBinaryNode {
  final dynamic Function(dynamic, dynamic) binaryFunction;

  BinaryLambdaExecutionNode(
    this.binaryFunction,
    super.lhs,
    super.rhs, {
    required super.thread,
    required super.scope,
  });

  @override
  dynamic applyNotNull() => binaryFunction(lhsResult, rhsResult);
}
