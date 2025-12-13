import 'package:awesome_calculator/shql/execution/null_aware_binary_node.dart';

class EqualityExecutionNode extends NullAwareBinaryNode {
  EqualityExecutionNode(
    super.lhsTree,
    super.rhsTree, {
    required super.thread,
    required super.scope,
  });

  @override
  bool applyNotNull() => lhsResult == rhsResult;
}
