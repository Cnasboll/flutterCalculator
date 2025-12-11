import 'package:awesome_calculator/shql/execution/execution_node.dart';
import 'package:awesome_calculator/shql/execution/parent_execution_node.dart';

abstract class BinaryExecutionNode extends ParentExecutionNode {
  BinaryExecutionNode(
    ExecutionNode lhs,
    ExecutionNode rhs, {
    required super.scope,
  }) : super([lhs, rhs]);

  ExecutionNode get lhs => children[0];
  ExecutionNode get rhs => children[1];
}
