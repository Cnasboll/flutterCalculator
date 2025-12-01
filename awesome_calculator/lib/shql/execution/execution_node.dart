import 'package:awesome_calculator/shql/execution/runtime.dart';

abstract class ExecutionNode {
  bool tick(Runtime runtime) {
    if (completed) {
      return true;
    }
    completed = doTick(runtime);
    return completed;
  }

  bool doTick(Runtime runtime);

  bool completed = false;
  String? error;
  dynamic result;
  dynamic getResult() {
    return result;
  }
}
