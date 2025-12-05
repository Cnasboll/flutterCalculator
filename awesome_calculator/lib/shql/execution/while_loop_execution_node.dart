import 'package:awesome_calculator/shql/engine/engine.dart';
import 'package:awesome_calculator/shql/execution/execution_node.dart';
import 'package:awesome_calculator/shql/execution/lazy_execution_node.dart';
import 'package:awesome_calculator/shql/execution/runtime.dart';

class WhileLoopExecutionNode extends LazyExecutionNode {
  WhileLoopExecutionNode(super.node);

  ExecutionNode? _conditionNode;
  ExecutionNode? _bodyNode;

  @override
  Future<bool> doTick(Runtime runtime) async {
    if (_bodyNode == null) {
      _conditionNode ??= Engine.createExecutionNode(node.children[0]);
      if (!await _conditionNode!.tick(runtime)) {
        return false;
      }

      var conditionResult = _conditionNode!.result;
      if (!conditionResult) {
        return true;
      }
      _bodyNode = Engine.createExecutionNode(node.children[1]);
    }

    if (!await _bodyNode!.tick(runtime)) {
      return false;
    }
    result = _bodyNode!.result;
    _bodyNode = null;
    _conditionNode = null;
    return false;
  }
}
