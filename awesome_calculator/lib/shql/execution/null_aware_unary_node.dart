import 'package:awesome_calculator/shql/execution/unary_execution_node.dart';
import 'package:awesome_calculator/shql/execution/runtime.dart';

abstract class NullAwareUnaryNode extends UnaryExecutionNode {
  NullAwareUnaryNode(super.operand);

  @override
  Future<void> onChildrenComplete(Runtime runtime) async {
    if (operand.result == null) {
      result = null;
      return;
    }
    result = await evaluate(operand.result);
  }

  Future<dynamic> evaluate(dynamic operandResult);
}
