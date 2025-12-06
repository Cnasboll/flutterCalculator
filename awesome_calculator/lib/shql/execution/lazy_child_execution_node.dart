import 'package:awesome_calculator/shql/execution/execution_node.dart';
import 'package:awesome_calculator/shql/execution/lazy_execution_node.dart';
import 'package:awesome_calculator/shql/execution/runtime.dart';

abstract class LazyChildExecutionNode extends LazyExecutionNode {
  LazyChildExecutionNode(super.node);

  ExecutionNode get child => _child!;

  ExecutionNode? createChildNode(Runtime runtime);

  @override
  Future<bool> doTick(Runtime runtime) async {
    _child ??= createChildNode(runtime);
    if (_child == null) {
      return true;
    }
    if (!await tickChild(_child!, runtime)) {
      return false;
    }
    return true;
  }

  ExecutionNode? _child;
}
