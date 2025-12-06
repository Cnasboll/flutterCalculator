import 'package:awesome_calculator/shql/engine/cancellation_token.dart';
import 'package:awesome_calculator/shql/execution/execution_node.dart';
import 'package:awesome_calculator/shql/execution/runtime.dart';

class BreakStatementExecutionNode extends ExecutionNode {
  @override
  Future<bool> doTick(
    Runtime runtime,
    CancellationToken? cancellationToken,
  ) async {
    var breakTarget = runtime.currentBreakTarget;
    if (breakTarget == null) {
      error = 'Break statement used outside of a loop.';
      return true;
    }
    breakTarget.breakExecution();
    return true;
  }
}
