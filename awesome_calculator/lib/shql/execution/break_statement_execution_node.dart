import 'package:awesome_calculator/shql/engine/cancellation_token.dart';
import 'package:awesome_calculator/shql/execution/execution_node.dart';
import 'package:awesome_calculator/shql/execution/runtime/execution.dart';

class BreakStatementExecutionNode extends ExecutionNode {
  BreakStatementExecutionNode({required super.thread, required super.scope});
  @override
  Future<TickResult> doTick(
    Execution execution,
    CancellationToken? cancellationToken,
  ) async {
    var breakTarget = thread.currentBreakTarget;
    if (breakTarget == null) {
      error = 'Break statement used outside of a loop.';
      return TickResult.completed;
    }
    breakTarget.breakExecution();
    return TickResult.completed;
  }
}
