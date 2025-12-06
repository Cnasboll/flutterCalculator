import 'package:awesome_calculator/shql/engine/cancellation_token.dart';
import 'package:awesome_calculator/shql/engine/engine.dart';
import 'package:awesome_calculator/shql/execution/execution_node.dart';
import 'package:awesome_calculator/shql/execution/lazy_execution_node.dart';
import 'package:awesome_calculator/shql/execution/runtime.dart';

class WhileLoopExecutionNode extends LazyExecutionNode {
  WhileLoopExecutionNode(super.node);

  ExecutionNode? _conditionNode;
  ExecutionNode? _bodyNode;
  BreakTarget? _breakTarget;
  bool _hasBodyResult = false;

  @override
  Future<bool> doTick(
    Runtime runtime,
    CancellationToken? cancellationToken,
  ) async {
    if (_bodyNode == null) {
      _conditionNode ??= Engine.createExecutionNode(node.children[0]);

      // If the body has been executd once, keep the result the last body and void tickChild() as that would
      // always make the while loop evaluate to false.
      if (!(_hasBodyResult
          ? await _conditionNode!.tick(runtime, cancellationToken)
          : await tickChild(_conditionNode!, runtime, cancellationToken))) {
        return false;
      }

      var conditionResult = _conditionNode!.result;
      if (!conditionResult) {
        return true;
      }
      if (await runtime.check(cancellationToken)) {
        return true;
      }
      _bodyNode = Engine.createExecutionNode(node.children[1]);
      _breakTarget = runtime.pushBreakTarget();
    }

    if (!await tickChild(_bodyNode!, runtime, cancellationToken)) {
      if (_breakTarget?.clearContinued() ?? false) {
        _bodyNode = null;
        _conditionNode = null;
      }
      return false;
    }
    runtime.popBreakTarget();
    _hasBodyResult = true;
    if (await (_breakTarget?.check(cancellationToken) ?? false)) {
      return true;
    }
    _bodyNode = null;
    _conditionNode = null;
    return false;
  }
}
