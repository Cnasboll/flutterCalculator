import 'package:awesome_calculator/shql/execution/binary_execution_node.dart';
import 'package:awesome_calculator/shql/execution/runtime.dart';

abstract class NullAwareBinaryNode extends BinaryExecutionNode {
  NullAwareBinaryNode(super.lhs, super.rhs);

  @override
  Future<void> onChildrenComplete(Runtime runtime) async {
    if (lhs.result == null || rhs.result == null) {
      result = null;
      return;
    }
    result = await evaluate(lhs.result, rhs.result);
  }

  Future<dynamic> evaluate(dynamic lhsResult, dynamic rhsResult);
}
