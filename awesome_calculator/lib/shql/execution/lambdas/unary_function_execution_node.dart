import 'package:awesome_calculator/shql/engine/cancellation_token.dart';
import 'package:awesome_calculator/shql/execution/execution_node.dart';
import 'package:awesome_calculator/shql/execution/runtime/execution.dart';
import 'package:awesome_calculator/shql/execution/runtime/runtime.dart';

class UnaryFunctionExecutionNode extends ExecutionNode {
  final UnaryFunction unaryFunction;
  final dynamic argument;

  UnaryFunctionExecutionNode(
    this.unaryFunction,
    this.argument, {
    required super.thread,
    required super.scope,
  });

  @override
  Future<TickResult> doTick(
    Execution execution,
    CancellationToken? cancellationToken,
  ) async {
    result = await unaryFunction.function(execution, this, argument);
    return TickResult.completed;
  }
}
