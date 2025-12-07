import 'package:awesome_calculator/shql/engine/cancellation_token.dart';
import 'package:awesome_calculator/shql/engine/engine.dart';
import 'package:awesome_calculator/shql/execution/assignment_execution_node.dart';
import 'package:awesome_calculator/shql/execution/execution_node.dart';
import 'package:awesome_calculator/shql/execution/lazy_execution_node.dart';
import 'package:awesome_calculator/shql/execution/runtime.dart';
import 'package:awesome_calculator/shql/tokenizer/token.dart';

class ForLoopExecutionNode extends LazyExecutionNode {
  ForLoopExecutionNode(super.node);

  AssignmentExecutionNode? _initializationNode;
  int _variableIdentifier = -1;
  dynamic _initialIteratorValue;
  bool _initializationDone = false;
  ExecutionNode? _targetNode;
  ExecutionNode? _stepNode;
  ExecutionNode? _bodyNode;
  BreakTarget? _breakTarget;

  @override
  Future<bool> doTick(
    Runtime runtime,
    CancellationToken? cancellationToken,
  ) async {
    if (_breakTarget == null) {
      if (node.children.length != 4) {
        error = 'For loop must have initialization, target, step, and body.';
        return true;
      }

      var intializationNode = node.children[0];
      if (intializationNode.symbol != Symbols.assignment) {
        error = 'For loop initialization must be an assignment.';
        return true;
      }
      var identifierNode = intializationNode.children[0];
      if (identifierNode.symbol != Symbols.identifier) {
        error = 'For loop initialization must be an assignment to a variable.';
        return true;
      }
      if (identifierNode.children.isNotEmpty) {
        error = 'For loop initialization cannot be an indexed assignment.';
        return true;
      }
      _variableIdentifier = identifierNode.qualifier!;
      _initializationNode = Engine.tryCreateAssignmentExecutionNode(
        intializationNode,
      );
      if (_initializationNode == null) {
        error = 'Could not create assignment execution node.';
        return true;
      }
      _targetNode = Engine.createExecutionNode(node.children[1]);
      _stepNode = Engine.createExecutionNode(node.children[2]);
      _breakTarget = runtime.pushBreakTarget();
    }
    if (!_initializationDone) {
      var initEvaluated = await tickChild(
        _initializationNode!,
        runtime,
        cancellationToken,
      );
      if (await runtime.check(cancellationToken)) {
        runtime.popBreakTarget();
        return true;
      }
      if (!initEvaluated) {
        return false;
      }
      _initializationDone = true;
      _initialIteratorValue = _initializationNode!.result;
    }

    var (currentIteratorValue, _) = runtime.resolveIdentifier(
      _variableIdentifier,
    );

    if (_bodyNode == null) {
      if (_stepNode == null) {
        _targetNode ??= Engine.createExecutionNode(node.children[1]);
        var targetEvaluated = await tickChild(
          _targetNode!,
          runtime,
          cancellationToken,
        );

        var continued = _breakTarget?.clearContinued() ?? false;
        if (await runtime.check(cancellationToken)) {
          runtime.popBreakTarget();
          return true;
        }
        if (!targetEvaluated && !continued) {
          return false;
        }
        if (!continued) {
          var targetValue = _targetNode!.result;
          bool iteratingForward = targetValue >= _initialIteratorValue;
          bool conditionMet = iteratingForward
              ? currentIteratorValue >= targetValue
              : currentIteratorValue <= targetValue;
          if (conditionMet) {
            runtime.popBreakTarget();
            return true;
          }
          // We reset the target node in every iteration to allow re-evaluation
          _targetNode = null;
        }
      }
      _stepNode ??= Engine.createExecutionNode(node.children[2]);
      var stepEvaluated = await tickChild(
        _stepNode!,
        runtime,
        cancellationToken,
      );
      var continued = _breakTarget?.clearContinued() ?? false;
      if (await runtime.check(cancellationToken)) {
        runtime.popBreakTarget();
        return true;
      }
      if (!stepEvaluated && !continued) {
        return false;
      }

      if (!continued) {
        var stepValue = _stepNode!.result;
        runtime.setVariable(
          _variableIdentifier,
          currentIteratorValue + stepValue,
        );
        // We reset the step node in every iteration to allow re-evaluation
        _stepNode = null;
      }
    }
    _bodyNode ??= Engine.createExecutionNode(node.children[3]);
    var bodyEvaluated = await tickChild(_bodyNode!, runtime, cancellationToken);
    var continued = _breakTarget?.clearContinued() ?? false;
    if (await runtime.check(cancellationToken)) {
      runtime.popBreakTarget();
      return true;
    }
    if (!bodyEvaluated && !continued) {
      return false;
    }
    _bodyNode = null;
    return true;
  }
}
