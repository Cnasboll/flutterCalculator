import 'package:awesome_calculator/shql/execution/execution_node.dart';
import 'package:awesome_calculator/shql/execution/runtime.dart';

class AprioriExecutionNode extends ExecutionNode {
  AprioriExecutionNode(dynamic result) {
    this.result = result;
    completed = true;
  }

  @override
  Future<bool> doTick(Runtime runtime) async {
    return true;
  }
}
