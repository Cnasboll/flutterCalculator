import 'package:awesome_calculator/shql/execution/null_aware_binary_node.dart';

class LessThanExecutionNode extends NullAwareBinaryNode {
  LessThanExecutionNode(super.lhs, super.rhs);

  @override
  dynamic evaluate(dynamic lhsResult, dynamic rhsResult) =>
      lhsResult < rhsResult;
}
