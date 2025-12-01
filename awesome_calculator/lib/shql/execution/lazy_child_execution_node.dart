import 'package:awesome_calculator/shql/execution/execution_node.dart';
import 'package:awesome_calculator/shql/execution/lazy_execution_node.dart';
import 'package:awesome_calculator/shql/execution/runtime.dart';

abstract class LazyChildExecutionNode extends LazyExecutionNode {
  LazyChildExecutionNode(super.node);

  ExecutionNode get child => _child!;

  ExecutionNode? createChildNode(Runtime runtime);

  @override
  bool doTick(Runtime runtime) {
    _child ??= createChildNode(runtime);
    if (_child == null) {
      return true;
    }
    if (!child.tick(runtime)) {
      return false;
    }
    result = child.result;
    return true;
  }

  ExecutionNode? _child;
}
