import 'package:awesome_calculator/shql/execution/runtime.dart';

abstract class ExecutionNode {

  // Tick a child node and update result and error accordingly.
  // The result for a parent is always the same as the last ticked child's result which propagates up the tree.
  Future<bool> tickChild(ExecutionNode child, Runtime runtime) async {
    if (await child.tick(runtime)) {
      result = child.result;
      error = child.error;
      return true;
    }
    return false;
  }

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
