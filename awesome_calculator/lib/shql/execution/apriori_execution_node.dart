import 'package:awesome_calculator/shql/engine/cancellation_token.dart';
import 'package:awesome_calculator/shql/execution/execution_node.dart';
import 'package:awesome_calculator/shql/execution/runtime.dart';

class AprioriExecutionNode extends ExecutionNode {
  AprioriExecutionNode(dynamic result, {required super.scope}) {
    this.result = result;
    completed = true;
  }

  @override
  Future<bool> doTick(
    Runtime runtime,
    CancellationToken? cancellationToken,
  ) async {
    return true;
  }
}
