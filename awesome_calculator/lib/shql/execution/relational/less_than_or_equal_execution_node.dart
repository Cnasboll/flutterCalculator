import 'package:awesome_calculator/shql/execution/null_aware_binary_node.dart';

class LessThanOrEqualExecutionNode extends NullAwareBinaryNode {
  LessThanOrEqualExecutionNode(super.lhs, super.rhs);

  @override
  dynamic evaluate(dynamic lhsResult, dynamic rhsResult) =>
      lhsResult <= rhsResult;
}
