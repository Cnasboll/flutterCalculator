import 'package:awesome_calculator/shql/execution/lazy_execution_node.dart';
import 'package:awesome_calculator/shql/execution/runtime.dart';

class ConstantNode<T> extends LazyExecutionNode {
  ConstantNode(super.node);

  @override
  bool doTick(Runtime runtime) {
    result = runtime.constants.getByIndex(node.qualifier!) as T;
    return true;
  }
}
