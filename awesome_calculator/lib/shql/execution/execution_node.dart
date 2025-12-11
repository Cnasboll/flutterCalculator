import 'package:awesome_calculator/shql/engine/cancellation_token.dart';
import 'package:awesome_calculator/shql/execution/runtime.dart';

abstract class ExecutionNode {
  final Scope scope;

  ExecutionNode({required this.scope});

  // Tick a child node and update result and error accordingly.
  // The result for a parent is always the same as the last ticked child's result which propagates up the tree.
  Future<bool> tickChild(
    ExecutionNode child,
    Runtime runtime,
    CancellationToken? cancellationToken,
  ) async {
    if (await child.tick(runtime, cancellationToken)) {
      result = child.result;
      error = child.error;
      return true;
    }
    return false;
  }

  Future<bool> tick(
    Runtime runtime, [
    CancellationToken? cancellationToken,
  ]) async {
    if (completed) {
      return true;
    }
    completed = await doTick(runtime, cancellationToken);
    return completed;
  }

  Future<bool> doTick(Runtime runtime, CancellationToken? cancellationToken);
  bool completed = false;
  String? error;
  dynamic result;
  dynamic getResult() {
    return result;
  }
}
