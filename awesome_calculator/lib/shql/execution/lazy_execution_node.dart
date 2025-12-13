import 'package:awesome_calculator/shql/execution/execution_node.dart';
import 'package:awesome_calculator/shql/parser/parse_tree.dart';

abstract class LazyExecutionNode extends ExecutionNode {
  final ParseTree node;
  LazyExecutionNode(this.node, {required super.thread, required super.scope});
}
