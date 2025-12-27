import 'package:awesome_calculator/shql/engine/cancellation_token.dart';
import 'package:awesome_calculator/shql/execution/execution_node.dart';
import 'package:awesome_calculator/shql/execution/runtime/execution.dart';

class IndexToExecutionNode extends ExecutionNode {
  IndexToExecutionNode(
    this.indexable,
    this.index, {
    required super.thread,
    required super.scope,
  });

  dynamic indexable;
  dynamic index;

  @override
  Future<TickResult> doTick(
    Execution execution,
    CancellationToken? cancellationToken,
  ) {
    result = indexable[index];
    return Future.value(TickResult.completed);
  }

  void assign(dynamic value) {
    indexable[index] = value;
  }
}
