import 'package:awesome_calculator/shql/engine/cancellation_token.dart';
import 'package:awesome_calculator/shql/execution/execution_node.dart';
import 'package:awesome_calculator/shql/execution/runtime.dart';

class LambdaExpressionExecutionNode extends ExecutionNode {
  LambdaExpressionExecutionNode(this.name, UserFunction result) {
    this.result = result;
    completed = true;
  }

  final String name;

  @override
  Future<bool> doTick(
    Runtime runtime,
    CancellationToken? cancellationToken,
  ) async {
    return true;
  }
}
