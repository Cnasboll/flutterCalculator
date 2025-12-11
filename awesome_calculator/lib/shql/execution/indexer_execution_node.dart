import 'package:awesome_calculator/shql/execution/null_aware_binary_node.dart';

class IndexerExecutionNode extends NullAwareBinaryNode {
  IndexerExecutionNode(super.lhs, super.rhs, {required super.scope});

  @override
  Future<dynamic> evaluate(dynamic lhsResult, dynamic rhsResult) async =>
      lhsResult[rhsResult];
}
