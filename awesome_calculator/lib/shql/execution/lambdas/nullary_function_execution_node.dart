import 'package:awesome_calculator/shql/engine/cancellation_token.dart';
import 'package:awesome_calculator/shql/execution/execution_node.dart';
import 'package:awesome_calculator/shql/execution/runtime.dart';

class NullaryFunctionExecutionNode extends ExecutionNode {
  final NullaryFunction nullaryFunction;

  NullaryFunctionExecutionNode(
    this.nullaryFunction, {
    required super.thread,
    required super.scope,
  });

  @override
  Future<TickResult> doTick(
    Runtime runtime,
    CancellationToken? cancellationToken,
  ) async {
    result = await nullaryFunction.function(this);
    return TickResult.completed;
  }
}
