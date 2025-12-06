import 'package:awesome_calculator/shql/execution/boolean/boolean_exeuction_node.dart';

class AndExecutionNode extends BooleanExecutionNode {
  AndExecutionNode(super.lhs, super.rhs);

  @override
  bool shortCircuit(bool lhsResult) {
    if (!lhsResult) {
      result = false;
      return true;
    }
    return false;
  }

  @override
  Future<bool> evaluate(bool lhsResult, bool rhsResult) async =>
      lhsResult && rhsResult;
}
