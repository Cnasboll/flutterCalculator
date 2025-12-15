import 'package:awesome_calculator/shql/engine/cancellation_token.dart';
import 'package:awesome_calculator/shql/engine/engine.dart';
import 'package:awesome_calculator/shql/execution/execution_node.dart';
import 'package:awesome_calculator/shql/execution/lazy_execution_node.dart';
import 'package:awesome_calculator/shql/execution/runtime.dart';

abstract class LazyParentExecutionNode extends LazyExecutionNode {
  LazyParentExecutionNode(
    super.node, {
    required super.thread,
    required super.scope,
  });

  @override
  Future<TickResult> doTick(
    Runtime runtime,
    CancellationToken? cancellationToken,
  ) async {
    if (children == null) {
      List<ExecutionNode> r = [];
      for (var child in node.children.reversed) {
        var childRuntime = Engine.createExecutionNode(child, thread, scope);
        if (childRuntime == null) {
          error = 'Failed to create execution node for child node.';
          return TickResult.completed;
        }

        r.add(childRuntime);
      }
      children = r.reversed.toList();
      return TickResult.delegated;
    }

    result = evaluate();
    return TickResult.completed;
  }

  dynamic evaluate();
  List<ExecutionNode>? children;
}
