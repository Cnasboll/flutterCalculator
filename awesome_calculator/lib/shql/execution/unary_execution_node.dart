import 'package:awesome_calculator/shql/execution/execution_node.dart';
import 'package:awesome_calculator/shql/execution/parent_execution_node.dart';

abstract class UnaryExecutionNode extends ParentExecutionNode {
  UnaryExecutionNode(ExecutionNode operand) : super([operand]);

  ExecutionNode get operand => children[0];
}
