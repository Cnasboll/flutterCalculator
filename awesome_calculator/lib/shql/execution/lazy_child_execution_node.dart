import 'package:awesome_calculator/shql/engine/cancellation_token.dart';
import 'package:awesome_calculator/shql/execution/execution_node.dart';
import 'package:awesome_calculator/shql/execution/lazy_execution_node.dart';
import 'package:awesome_calculator/shql/execution/runtime.dart';

abstract class LazyChildExecutionNode extends LazyExecutionNode {
  LazyChildExecutionNode(super.node);

  ExecutionNode get child => _child!;

  ExecutionNode? createChildNode(Runtime runtime);

  @override
  Future<bool> doTick(
    Runtime runtime,
    CancellationToken? cancellationToken,
  ) async {
    if (await runtime.check(cancellationToken)) {
      return true;
    }
    _child ??= createChildNode(runtime);
    if (_child == null) {
      return true;
    }
    if (!await tickChild(_child!, runtime, cancellationToken)) {
      return false;
    }
    if (await runtime.check(cancellationToken)) {
      return true;
    }
    return true;
  }

  ExecutionNode? _child;
}
