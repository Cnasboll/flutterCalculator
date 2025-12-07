import 'package:awesome_calculator/shql/engine/cancellation_token.dart';
import 'package:awesome_calculator/shql/engine/engine.dart';
import 'package:awesome_calculator/shql/execution/execution_node.dart';
import 'package:awesome_calculator/shql/execution/lazy_execution_node.dart';
import 'package:awesome_calculator/shql/execution/runtime.dart';

class RepeatUntilLoopExecutionNode extends LazyExecutionNode {
  RepeatUntilLoopExecutionNode(super.node);

  ExecutionNode? _conditionNode;
  ExecutionNode? _bodyNode;
  BreakTarget? _breakTarget;

  @override
  Future<bool> doTick(
    Runtime runtime,
    CancellationToken? cancellationToken,
  ) async {
    _breakTarget ??= runtime.pushBreakTarget();
    if (_conditionNode == null) {
      _bodyNode ??= Engine.createExecutionNode(node.children[0]);
      var bodyEvaluated = await tickChild(
        _bodyNode!,
        runtime,
        cancellationToken,
      );
      var continued = _breakTarget?.clearContinued() ?? false;
      var cancelledOrBreak = await runtime.check(cancellationToken);
      if (cancelledOrBreak) {
        runtime.popBreakTarget();
        return true;
      }

      _bodyNode = null;
      if (bodyEvaluated || continued) {
        _conditionNode = Engine.createExecutionNode(node.children[1]);
      } else {
        return false;
      }
    }

    var conditionEvaluated = await _conditionNode!.tick(
      runtime,
      cancellationToken,
    );
    var terminated = conditionEvaluated && _conditionNode!.result == true;
    var continued = _breakTarget?.clearContinued() ?? false;
    var cancelledOrBreak = await runtime.check(cancellationToken);
    if (conditionEvaluated || continued || cancelledOrBreak) {
      _conditionNode = null;
      if (cancelledOrBreak || terminated) {
        runtime.popBreakTarget();
        return true;
      }
    }
    // Keep repeating
    return false;
  }
}
