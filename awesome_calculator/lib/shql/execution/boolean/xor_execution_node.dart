import 'package:awesome_calculator/shql/execution/boolean/boolean_exeuction_node.dart';

class XorExecutionNode extends BooleanExecutionNode {
  XorExecutionNode(super.lhs, super.rhs);

  @override
  bool shortCircuit(bool lhsResult) {
    return false;
  }

  @override
  Future<bool> evaluate(bool lhsResult, bool rhsResult) async =>
      lhsResult ^ rhsResult;
}
