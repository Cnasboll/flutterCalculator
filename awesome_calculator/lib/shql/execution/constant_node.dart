import 'package:awesome_calculator/shql/execution/lazy_execution_node.dart';
import 'package:awesome_calculator/shql/parser/constants_set.dart';

class ConstantNode<T> extends LazyExecutionNode {
  ConstantNode(super.node);

  @override
  bool doTick(ConstantsSet constantsSet) {
    result = constantsSet.constants.constants[node.qualifier!] as T;
    return true;
  }
}
