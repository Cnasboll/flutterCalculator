import 'package:awesome_calculator/shql/execution/execution_node.dart';
import 'package:awesome_calculator/shql/execution/runtime.dart';

class NullaryLambdaExecutionNode extends ExecutionNode {
  final dynamic Function() nullaryFunction;

  NullaryLambdaExecutionNode(this.nullaryFunction);

  @override
  Future<bool> doTick(Runtime runtime) async {
    result = await nullaryFunction();
    return true;
  }
}
