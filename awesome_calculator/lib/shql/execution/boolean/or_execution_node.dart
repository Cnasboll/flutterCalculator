import 'package:awesome_calculator/shql/execution/boolean/boolean_exeuction_node.dart';

class OrExecutionNode extends BooleanExecutionNode {
  OrExecutionNode(super.lhs, super.rhs);

  @override
  bool shortCircuit(bool lhsResult) {
    if (lhsResult) {
      result = true;
      return true;
    }
    return false;
  }

  @override
  bool evaluate(bool lhsResult, bool rhsResult) => lhsResult || rhsResult;
}
