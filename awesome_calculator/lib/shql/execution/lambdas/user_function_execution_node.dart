import 'package:awesome_calculator/shql/engine/cancellation_token.dart';
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
  ReturnTarget? _returnTarget;

  @override
  Future<bool> doTick(
    Runtime runtime,
    CancellationToken? cancellationToken,
  ) async {
    if (_returnTarget == null) {
      // Tick current argument nodes
      while (_argumentIndex < arguments.length) {
        if (!await tickChild(
          arguments[_argumentIndex],
          runtime,
          cancellationToken,
        )) {
          return false;
        }
        if (await runtime.check(cancellationToken)) {
          return true;
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
        var argument = arguments[i].result;
        if (argument is UserFunction) {
          runtime.setUserFunction(argumentIdentifiers[i], argument);
        } else {
          runtime.assignVariable(argumentIdentifiers[i], argument, true);
        }
      }
      _returnTarget = runtime.pushReturnTarget();
    }
    var returnTarget = _returnTarget!;
    // Tick the body
    if (!await tickChild(body, runtime, cancellationToken)) {
      // Handle return value
      if (await returnTarget.check(cancellationToken)) {
        if (returnTarget.hasReturnValue) {
          result = returnTarget.returnValue;
        }
        return true;
      }
      return false;
    }

    runtime.popScope();
    runtime.popReturnTarget();
    return true;
  }
}
