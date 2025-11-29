import 'package:awesome_calculator/shql/execution/binary_execution_node.dart';
import 'package:awesome_calculator/shql/execution/execution_node.dart';
import 'package:awesome_calculator/shql/execution/identifier_node.dart';
import 'package:awesome_calculator/shql/parser/constants_set.dart';

class AssignmentExecutionNode extends BinaryExecutionNode {
  AssignmentExecutionNode(super.lhs, super.rhs);

  @override
  bool onChildComplete(int index, ExecutionNode child) {
    if (index == 0) {
      // Left-hand side must be an identifier.
      if (child is! IdentifierExecutionNode) {
        error = "Left-hand side of assignment must be an identifier.";
        return false;
      }
    }
    return true;
  }

  @override
  void onChildrenComplete(ConstantsSet constantsSet) {
    var identifierNode = lhs as IdentifierExecutionNode;
    var identifier = identifierNode.node.qualifier!;
    constantsSet.setVariable(identifier, rhs.result);
    result = rhs.result;
  }
}
