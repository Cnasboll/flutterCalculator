import 'package:awesome_calculator/shql/engine/cancellation_token.dart';
import 'package:awesome_calculator/shql/execution/lazy_execution_node.dart';
import 'package:awesome_calculator/shql/execution/runtime.dart';
import 'package:awesome_calculator/shql/parser/constants_set.dart';

class ConstantNode<T> extends LazyExecutionNode {
  ConstantNode(super.node, {required super.scope});

  @override
  Future<bool> doTick(
    Runtime runtime,
    CancellationToken? cancellationToken,
  ) async {
    if (await runtime.check(cancellationToken)) {
      return true;
    }
    Scope? currentScope = scope;
    ConstantsTable<dynamic>? constants;
    while (currentScope != null) {
      constants ??= currentScope.constants;
      if (constants != null) {
        break;
      }
      currentScope = currentScope.parent;
    }
    if (constants == null) {
      error = "No constants table found in scope chain.";
      return true;
    }
    result = constants.getByIndex(node.qualifier!);
    return true;
  }
}
