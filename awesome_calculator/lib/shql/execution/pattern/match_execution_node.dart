import 'package:awesome_calculator/shql/execution/pattern/regexp_execution_node.dart';

class MatchExecutionNode extends RegexpExecutionNode {
  MatchExecutionNode(super.rhs, super.lhs);

  @override
  dynamic evaluate(dynamic lhsResult, dynamic rhsResult) =>
      matches(lhsResult, rhsResult);
}
