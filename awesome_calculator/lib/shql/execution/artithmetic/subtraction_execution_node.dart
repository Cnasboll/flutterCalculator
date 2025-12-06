import 'package:awesome_calculator/shql/execution/null_aware_binary_node.dart';

class SubtractionExecutionNode extends NullAwareBinaryNode {
  SubtractionExecutionNode(super.lhs, super.rhs);

  @override
  Future<dynamic> evaluate(dynamic lhsResult, dynamic rhsResult) async =>
      lhsResult - rhsResult;
}
