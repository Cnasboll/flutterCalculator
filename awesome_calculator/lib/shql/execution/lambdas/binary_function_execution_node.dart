import 'package:awesome_calculator/shql/engine/cancellation_token.dart';
import 'package:awesome_calculator/shql/execution/execution_node.dart';
import 'package:awesome_calculator/shql/execution/runtime/execution.dart';
import 'package:awesome_calculator/shql/execution/runtime/runtime.dart';

class BinaryFunctionExecutionNode extends ExecutionNode {
  final BinaryFunction binaryFunction;
  final dynamic argument1;
  final dynamic argument2;

  BinaryFunctionExecutionNode(
    this.binaryFunction,
    this.argument1,
    this.argument2, {
    required super.thread,
    required super.scope,
  });

  @override
  Future<TickResult> doTick(
    Execution execution,
    CancellationToken? cancellationToken,
  ) async {
    result = await binaryFunction.function(
      execution,
      this,
      argument1,
      argument2,
    );
    return TickResult.completed;
  }
}
