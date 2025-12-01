import 'package:awesome_calculator/shql/execution/binary_execution_node.dart';
import 'package:awesome_calculator/shql/execution/runtime.dart';

abstract class NullAwareBinaryNode extends BinaryExecutionNode {
  NullAwareBinaryNode(super.lhs, super.rhs);

  @override
  void onChildrenComplete(Runtime runtime) {
    if (lhs.result == null || rhs.result == null) {
      result = null;
      return;
    }
    result = evaluate(lhs.result, rhs.result);
  }

  dynamic evaluate(dynamic lhsResult, dynamic rhsResult);
}
