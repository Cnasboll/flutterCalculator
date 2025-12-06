import 'package:awesome_calculator/shql/execution/execution_node.dart';
import 'package:awesome_calculator/shql/execution/runtime.dart';

abstract class BooleanExecutionNode extends ExecutionNode {
  BooleanExecutionNode(this.lhs, this.rhs);

  @override
  Future<bool> doTick(Runtime runtime) async {
    if (await tickChild(lhs, runtime)) {
      var lhsResult = lhs.result is bool ? lhs.result : lhs.result != 0;
      if (shortCircuit(lhsResult)) {
        return true;
      }
      if (!await tickChild(rhs, runtime)) {
        return false;
      }

      var rhsResult = rhs.result is bool ? rhs.result : rhs.result != 0;
      result = evaluate(lhsResult, rhsResult);
      return true;
    }
    return false;
  }

  bool shortCircuit(bool lhsResult);
  bool evaluate(bool lhsResult, bool rhsResult);

  ExecutionNode lhs;
  ExecutionNode rhs;
}
