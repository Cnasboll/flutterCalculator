import 'package:awesome_calculator/shql/engine/engine.dart';
import 'package:awesome_calculator/shql/execution/execution_node.dart';
import 'package:awesome_calculator/shql/execution/lazy_execution_node.dart';
import 'package:awesome_calculator/shql/execution/runtime.dart';

class IfStatementExecutionNode extends LazyExecutionNode {
  IfStatementExecutionNode(super.node);

  ExecutionNode? _conditionNode;
  ExecutionNode? _branchNode;

  @override
  Future<bool> doTick(Runtime runtime) async {
    if (_branchNode != null) {
      if (!await _branchNode!.tick(runtime)) {
        return false;
      }
      result = _branchNode!.result;
      return true;
    }

    _conditionNode ??= Engine.createExecutionNode(node.children[0]);
    if (!await _conditionNode!.tick(runtime)) {
      return false;
    }

    var conditionResult = _conditionNode!.result;
    if (conditionResult == true) {
      _branchNode = Engine.createExecutionNode(node.children[1]);
    } else if (node.children.length > 2) {
      // Else branch
      _branchNode = Engine.createExecutionNode(node.children[2]);
    } else {
      result = null;
      return true;
    }
    if (!await _branchNode!.tick(runtime)) {
      return false;
    }
    result = _branchNode!.result;
    return true;
  }
}
