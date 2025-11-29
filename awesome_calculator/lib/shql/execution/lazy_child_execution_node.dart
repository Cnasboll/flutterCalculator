import 'package:awesome_calculator/shql/execution/execution_node.dart';
import 'package:awesome_calculator/shql/execution/lazy_execution_node.dart';
import 'package:awesome_calculator/shql/parser/constants_set.dart';

abstract class LazyChildExecutionNode extends LazyExecutionNode {
  LazyChildExecutionNode(super.node);

  ExecutionNode get child => _child!;

  ExecutionNode? createChildNode(ConstantsSet constantsSet);

  @override
  bool doTick(ConstantsSet constantsSet) {
    _child ??= createChildNode(constantsSet);
    if (_child == null) {
      return true;
    }
    if (!child.tick(constantsSet)) {
      return false;
    }
    result = child.result;
    return true;
  }

  ExecutionNode? _child;
}
