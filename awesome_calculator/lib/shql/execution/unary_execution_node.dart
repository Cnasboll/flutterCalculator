import 'package:awesome_calculator/shql/engine/cancellation_token.dart';
import 'package:awesome_calculator/shql/engine/engine.dart';
import 'package:awesome_calculator/shql/execution/execution_node.dart';
import 'package:awesome_calculator/shql/execution/lazy_execution_node.dart';
import 'package:awesome_calculator/shql/execution/runtime.dart';

abstract class UnaryExecutionNode extends LazyExecutionNode {
  UnaryExecutionNode(super.node, {required super.thread, required super.scope});

  @override
  Future<TickResult> doTick(
    Runtime runtime,
    CancellationToken? cancellationToken,
  ) async {
    if (operand == null) {
      operand = Engine.createExecutionNode(node, thread, scope);
      return TickResult.delegated;
    }

    result = await apply();
    return TickResult.completed;
  }

  ExecutionNode? operand;
  dynamic get operandResult => operand!.result;
  Future<dynamic> apply();
}
