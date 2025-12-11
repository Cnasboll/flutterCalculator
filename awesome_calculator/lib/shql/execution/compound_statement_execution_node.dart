import 'package:awesome_calculator/shql/engine/cancellation_token.dart';
import 'package:awesome_calculator/shql/engine/engine.dart';
import 'package:awesome_calculator/shql/execution/execution_node.dart';
import 'package:awesome_calculator/shql/execution/lazy_execution_node.dart';
import 'package:awesome_calculator/shql/execution/runtime.dart';

class CompoundStatementExecutionNode extends LazyExecutionNode {
  CompoundStatementExecutionNode(super.node, {required super.scope});

  @override
  Future<bool> doTick(
    Runtime runtime,
    CancellationToken? cancellationToken,
  ) async {
    if (_statementIndex == -1) {
      _localScope = Scope(Object(), parent: scope);
      _statementIndex = 0;
    }

    while (_statementIndex < node.children.length) {
      _currentStatement ??= Engine.createExecutionNode(
        node.children[_statementIndex],
        _localScope,
      );
      if (_currentStatement == null) {
        error = 'Failed to create execution node for statement.';
        return true;
      }
      if (!await tickChild(_currentStatement!, runtime, cancellationToken)) {
        return false;
      }
      if (await runtime.check(cancellationToken)) {
        return true;
      }

      ++_statementIndex;
      _currentStatement = null;
    }
    _currentStatement = null;
    return true;
  }

  int _statementIndex = -1;
  ExecutionNode? _currentStatement;
  late Scope _localScope;
}
