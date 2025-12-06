import 'package:awesome_calculator/shql/engine/cancellation_token.dart';
import 'package:awesome_calculator/shql/execution/execution_node.dart';
import 'package:awesome_calculator/shql/execution/runtime.dart';

abstract class BooleanExecutionNode extends ExecutionNode {
  BooleanExecutionNode(this.lhs, this.rhs);

  @override
  Future<bool> doTick(
    Runtime runtime,
    CancellationToken? cancellationToken,
  ) async {
    if (await runtime.check(cancellationToken)) {
      return true;
    }
    if (await tickChild(lhs, runtime, cancellationToken)) {
      if (await runtime.check(cancellationToken)) {
        return true;
      }
      var lhsResult = lhs.result is bool ? lhs.result : lhs.result != 0;
      if (shortCircuit(lhsResult)) {
        return true;
      }
      if (!await tickChild(rhs, runtime, cancellationToken)) {
        return false;
      }
      if (await runtime.check(cancellationToken)) {
        return true;
      }

      var rhsResult = rhs.result is bool ? rhs.result : rhs.result != 0;
      result = await evaluate(lhsResult, rhsResult);
      return true;
    }
    return false;
  }

  bool shortCircuit(bool lhsResult);
  Future<bool> evaluate(bool lhsResult, bool rhsResult);

  ExecutionNode lhs;
  ExecutionNode rhs;
}
