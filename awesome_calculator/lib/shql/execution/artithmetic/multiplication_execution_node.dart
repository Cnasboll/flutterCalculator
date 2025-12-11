import 'package:awesome_calculator/shql/execution/null_aware_binary_node.dart';

class MultiplicationExecutionNode extends NullAwareBinaryNode {
  MultiplicationExecutionNode(super.lhs, super.rh, {required super.scope});

  @override
  Future<dynamic> evaluate(dynamic lhsResult, dynamic rhsResult) async =>
      lhsResult * rhsResult;
}
