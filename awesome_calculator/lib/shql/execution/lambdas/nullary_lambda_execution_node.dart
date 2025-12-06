import 'package:awesome_calculator/shql/engine/cancellation_token.dart';
import 'package:awesome_calculator/shql/execution/execution_node.dart';
import 'package:awesome_calculator/shql/execution/runtime.dart';

class NullaryLambdaExecutionNode extends ExecutionNode {
  final dynamic Function() nullaryFunction;

  NullaryLambdaExecutionNode(this.nullaryFunction);

  @override
  Future<bool> doTick(
    Runtime runtime,
    CancellationToken? cancellationToken,
  ) async {
    if (await runtime.check(cancellationToken)) {
      return true;
    }
    result = await nullaryFunction();
    return true;
  }
}
