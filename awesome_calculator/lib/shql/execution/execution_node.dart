import 'package:awesome_calculator/shql/parser/constants_set.dart';

abstract class ExecutionNode {
  bool tick(ConstantsSet constantsSet) {
    if (completed) {
      return true;
    }
    completed = doTick(constantsSet);
    return completed;
  }

  bool doTick(ConstantsSet constantsSet);

  bool completed = false;
  String? error;
  dynamic result;
  dynamic getResult() {
    return result;
  }
}
