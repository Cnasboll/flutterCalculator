import 'dart:math';
import 'package:awesome_calculator/shql/execution/null_aware_binary_node.dart';

class ExponentiationExecutionNode extends NullAwareBinaryNode {
  ExponentiationExecutionNode(super.lhs, super.rhs);

  @override
  dynamic evaluate(dynamic lhsResult, dynamic rhsResult) =>
      pow(lhsResult, rhsResult);
}
