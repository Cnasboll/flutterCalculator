import 'package:awesome_calculator/shql/engine/cancellation_token.dart';
import 'package:awesome_calculator/shql/engine/engine.dart';
import 'package:awesome_calculator/shql/execution/execution_node.dart';
import 'package:awesome_calculator/shql/execution/runtime.dart';

class UserFunctionExecutionNode extends ExecutionNode {
  UserFunctionExecutionNode(
    this.userFunction,
    this.arguments, {
    required super.scope,
  });

  final UserFunction userFunction;
  final List<ExecutionNode> arguments;
  ExecutionNode? body;
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

      var childScope = Scope(Object(), parent: userFunction.scope);
      // Assign argument values to identifiers
      var argumentIdentifiers = userFunction.argumentIdentifiers;
      for (int i = 0; i < argumentIdentifiers.length; i++) {
        var argument = arguments[i].result;
        if (argument is UserFunction) {
          // Define user function in child scope, in members directly so it is definetely shadowed
          childScope.members.defineUserFunction(
            argumentIdentifiers[i],
            argument,
          );
        } else {
          // Define variable child scope, in members directly so it is definetely shadowed
          childScope.members.setVariable(argumentIdentifiers[i], argument);
        }
      }
      _returnTarget = runtime.pushReturnTarget();
      body = Engine.createExecutionNode(userFunction.body, childScope);
    }
    var returnTarget = _returnTarget!;
    // Tick the body
    if (!await tickChild(body!, runtime, cancellationToken)) {
      // Handle return value
      if (await returnTarget.check(cancellationToken)) {
        if (returnTarget.hasReturnValue) {
          result = returnTarget.returnValue;
        }
        runtime.popReturnTarget();
        return true;
      }
      return false;
    }

    runtime.popReturnTarget();
    return true;
  }
}
