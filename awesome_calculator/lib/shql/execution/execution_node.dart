import 'package:awesome_calculator/shql/execution/runtime.dart';

abstract class ExecutionNode {
  Future<bool> tick(Runtime runtime) async {
    if (completed) {
      return true;
    }
    completed = await doTick(runtime);
    return completed;
  }

  Future<bool> doTick(Runtime runtime);
  bool completed = false;
  String? error;
  dynamic result;
  dynamic getResult() {
    return result;
  }
}
