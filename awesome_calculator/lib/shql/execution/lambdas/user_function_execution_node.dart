import 'package:awesome_calculator/shql/execution/execution_node.dart';
import 'package:awesome_calculator/shql/execution/runtime.dart';

class UserFunctionExecutionNode extends ExecutionNode {
  UserFunctionExecutionNode(
    this.argumentIdentifiers,
    this.arguments,
    this.body,
  );

  final List<int> argumentIdentifiers;
  final List<ExecutionNode> arguments;
  final ExecutionNode body;
  int _argumentIndex = 0;
  bool _scopePushed = false;

  @override
  Future<bool> doTick(Runtime runtime) async {
    if (!_scopePushed) {
      // Tick current argument nodes
      while (_argumentIndex < arguments.length) {
        if (!await tickChild(arguments[_argumentIndex], runtime)) {
          return false;
        }
        ++_argumentIndex;
      }

      var (success, error) = runtime.pushScope();
      if (!success) {
        // Handle the error, e.g., throw an exception or return false
        this.error = error;
        return false;
      }
      // Assign argument values to identifiers
      for (int i = 0; i < argumentIdentifiers.length; i++) {
        runtime.assignVariable(argumentIdentifiers[i], arguments[i].result);
      }
      _scopePushed = true;
    }
    // Tick the body
    if (!await tickChild(body, runtime)) {
      return false;
    }

    runtime.popScope();
    return true;
  }
}
