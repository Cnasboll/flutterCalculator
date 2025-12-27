import 'package:awesome_calculator/shql/engine/cancellation_token.dart';
import 'package:awesome_calculator/shql/execution/execution_node.dart';
import 'package:awesome_calculator/shql/execution/runtime/execution.dart';

class AprioriExecutionNode extends ExecutionNode {
  AprioriExecutionNode(
    dynamic result, {
    required super.thread,
    required super.scope,
  }) {
    this.result = result;
    completed = true;
  }

  @override
  Future<TickResult> doTick(
    Execution execution,
    CancellationToken? cancellationToken,
  ) async {
    return TickResult.completed;
  }
}
