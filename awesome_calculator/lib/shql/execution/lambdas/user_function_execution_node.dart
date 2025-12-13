import 'package:awesome_calculator/shql/engine/cancellation_token.dart';
import 'package:awesome_calculator/shql/engine/engine.dart';
import 'package:awesome_calculator/shql/execution/execution_node.dart';
import 'package:awesome_calculator/shql/execution/runtime.dart';
import 'package:awesome_calculator/shql/parser/parse_tree.dart';

class UserFunctionExecutionNode extends ExecutionNode {
  UserFunctionExecutionNode(
    this.userFunction,
    this.arguments, {
    required super.thread,
    required super.scope,
  });

  final UserFunction userFunction;
  final List<ParseTree> arguments;
  List<ExecutionNode>? _argumentsStack;
  ExecutionNode? body;

  @override
  Future<TickResult> doTick(
    Runtime runtime,
    CancellationToken? cancellationToken,
  ) async {
    if (_argumentsStack == null) {
      _argumentsStack = <ExecutionNode>[];
      for (var argument in arguments.reversed) {
        _argumentsStack!.add(
          Engine.createExecutionNode(argument, thread, scope)!,
        );
      }
      return TickResult.delegated;
    }

    if (returnTarget == null) {
      // TODO: Keep track of recursion depth and throw error if too deep
      var childScope = Scope(Object(), parent: userFunction.scope);
      // Assign argument values to identifiers
      var argumentIdentifiers = userFunction.argumentIdentifiers;
      var arguments = _argumentsStack!.reversed.toList();
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
      returnTarget = thread.pushReturnTarget();
      body = Engine.createExecutionNode(userFunction.body, thread, childScope);
      return TickResult.delegated;
    }

    error ??= body!.error;
    if (returnTarget!.hasReturnValue) {
      result ??= returnTarget!.returnValue;
    } else {
      result ??= body!.result;
    }

    return TickResult.completed;
  }
}
