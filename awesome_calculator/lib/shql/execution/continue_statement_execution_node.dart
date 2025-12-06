import 'package:awesome_calculator/shql/engine/cancellation_token.dart';
import 'package:awesome_calculator/shql/execution/execution_node.dart';
import 'package:awesome_calculator/shql/execution/runtime.dart';

class ContinueStatementExecutionNode extends ExecutionNode {
  @override
  Future<bool> doTick(
    Runtime runtime,
    CancellationToken? cancellationToken,
  ) async {
    var breakTarget = runtime.currentBreakTarget;
    if (breakTarget == null) {
      error = 'Continue statement used outside of a loop.';
      return true;
    }
    breakTarget.continueExecution();
    return true;
  }
}
