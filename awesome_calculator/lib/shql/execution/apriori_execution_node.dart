import 'package:awesome_calculator/shql/execution/execution_node.dart';
import 'package:awesome_calculator/shql/parser/constants_set.dart';

class AprioriExecutionNode extends ExecutionNode {
  AprioriExecutionNode(dynamic result) {
    this.result = result;
    completed = true;
  }

  @override
  bool doTick(ConstantsSet constantsSet) {
    return true;
  }
}
