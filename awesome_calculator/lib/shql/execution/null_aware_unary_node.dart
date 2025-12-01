import 'package:awesome_calculator/shql/execution/unary_execution_node.dart';
import 'package:awesome_calculator/shql/execution/runtime.dart';

abstract class NullAwareUnaryNode extends UnaryExecutionNode {
  NullAwareUnaryNode(super.operand);

  @override
  void onChildrenComplete(Runtime runtime) {
    if (operand.result == null) {
      result = null;
      return;
    }
    result = evaluate(operand.result);
  }

  dynamic evaluate(dynamic operandResult);
}
