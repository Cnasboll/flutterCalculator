import 'dart:core';

import 'package:awesome_calculator/shql/engine/cancellation_token.dart';
import 'package:awesome_calculator/shql/execution/apriori_execution_node.dart';
import 'package:awesome_calculator/shql/execution/operators/artithmetic/addition_execution_node.dart';
import 'package:awesome_calculator/shql/execution/operators/artithmetic/division_execution_node.dart';
import 'package:awesome_calculator/shql/execution/operators/artithmetic/modulus_execution_node.dart';
import 'package:awesome_calculator/shql/execution/operators/artithmetic/multiplication_execution_node.dart';
import 'package:awesome_calculator/shql/execution/operators/artithmetic/subtraction_execution_node.dart';
import 'package:awesome_calculator/shql/execution/operators/artithmetic/unary_minus_execution_node.dart';
import 'package:awesome_calculator/shql/execution/assignment_execution_node.dart';
import 'package:awesome_calculator/shql/execution/operators/boolean/and_execution_node.dart';
import 'package:awesome_calculator/shql/execution/operators/boolean/not_execution_node.dart';
import 'package:awesome_calculator/shql/execution/operators/boolean/or_execution_node.dart';
import 'package:awesome_calculator/shql/execution/operators/boolean/xor_execution_node.dart';
import 'package:awesome_calculator/shql/execution/break_statement_execution_node.dart';
import 'package:awesome_calculator/shql/execution/compound_statement_execution_node.dart';
import 'package:awesome_calculator/shql/execution/constant_node.dart';
import 'package:awesome_calculator/shql/execution/continue_statement_execution_node.dart';
import 'package:awesome_calculator/shql/execution/execution_node.dart';
import 'package:awesome_calculator/shql/execution/operators/artithmetic/exponentiation_execution_node.dart';
import 'package:awesome_calculator/shql/execution/for_loop_execution_node.dart';
import 'package:awesome_calculator/shql/execution/identifier_exeuction_node.dart';
import 'package:awesome_calculator/shql/execution/if_statement_execution_node.dart';
import 'package:awesome_calculator/shql/execution/lambdas/lambda_expression_execution_node.dart';
import 'package:awesome_calculator/shql/execution/list_literal_node.dart';
import 'package:awesome_calculator/shql/execution/map_literal_node.dart';
import 'package:awesome_calculator/shql/execution/member_access_execution_node.dart';
import 'package:awesome_calculator/shql/execution/operators/pattern/in_execution_node.dart';
import 'package:awesome_calculator/shql/execution/operators/pattern/match_execution_node.dart';
import 'package:awesome_calculator/shql/execution/operators/pattern/not_match_execution_node.dart';
import 'package:awesome_calculator/shql/execution/program_execution_node.dart';
import 'package:awesome_calculator/shql/execution/operators/relational/equality_execution_node.dart';
import 'package:awesome_calculator/shql/execution/operators/relational/greater_than_execution_node.dart';
import 'package:awesome_calculator/shql/execution/operators/relational/greater_than_or_equal_execution_node.dart';
import 'package:awesome_calculator/shql/execution/operators/relational/less_than_execution_node.dart';
import 'package:awesome_calculator/shql/execution/operators/relational/less_than_or_equal_execution_node.dart';
import 'package:awesome_calculator/shql/execution/operators/relational/not_equality_execution_node.dart';
import 'package:awesome_calculator/shql/execution/repeat_until_loop_execution_node.dart';
import 'package:awesome_calculator/shql/execution/return_statement_execution_node.dart';
import 'package:awesome_calculator/shql/execution/runtime.dart';
import 'package:awesome_calculator/shql/execution/tuple_literal_node.dart';
import 'package:awesome_calculator/shql/execution/while_loop_execution_node.dart';
import 'package:awesome_calculator/shql/parser/constants_set.dart';
import 'package:awesome_calculator/shql/parser/parse_tree.dart';
import 'package:awesome_calculator/shql/parser/parser.dart';
import 'package:awesome_calculator/shql/tokenizer/token.dart';

class RuntimeException implements Exception {
  final String message;

  RuntimeException(this.message);

  @override
  String toString() => 'RuntimeException: $message';
}

class Engine {
  static Future<dynamic> execute(
    String code, {
    Runtime? runtime,
    ConstantsSet? constantsSet,
    CancellationToken? cancellationToken,
  }) async {
    constantsSet ??= Runtime.prepareConstantsSet();
    runtime ??= Runtime.prepareRuntime(constantsSet);

    var program = Parser.parse(code, constantsSet);

    return await _execute(program, runtime, cancellationToken);
  }

  static Future<dynamic> calculate(
    String expression, {
    Runtime? runtime,
    ConstantsSet? constantsSet,
  }) async {
    constantsSet ??= Runtime.prepareConstantsSet();
    runtime ??= Runtime.prepareRuntime(constantsSet);
    var program = Parser.parse(expression, constantsSet);

    var result = await _calculate(program, runtime);

    if (result.$2 == false) {
      return null;
    }
    return result.$1;
  }

  static Future<dynamic> _execute(
    ParseTree parseTree,
    Runtime runtime,
    CancellationToken? cancellationToken,
  ) async {
    try {
      var executionNode = createExecutionNode(
        parseTree,
        runtime.mainThread,
        runtime.globalScope,
      );
      if (executionNode == null) {
        throw RuntimeException('Failed to create execution node.');
      }

      while ((cancellationToken == null || !await cancellationToken.check()) &&
          !await runtime.mainThread.tick(runtime, cancellationToken)) {
        await Future.delayed(const Duration(milliseconds: 1));
      }

      if (executionNode.error != null) {
        throw RuntimeException(executionNode.error!);
      }

      return executionNode.result;
    } finally {
      // Clean up any temporary state if needed in the future
      runtime.mainThread.executionStack.clear();
      runtime.mainThread.clearBreakTargets();
      runtime.mainThread.clearReturnTargets();
    }
  }

  static Future<(dynamic, bool)> _calculate(
    ParseTree parseTree,
    Runtime runtime,
  ) async {
    try {
      var executionNode = createExecutionNode(
        parseTree,
        runtime.mainThread,
        runtime.globalScope,
      );
      if (executionNode == null) {
        throw RuntimeException('Failed to create execution node.');
      }

      if (!await runtime.mainThread.tick(runtime)) {
        return (null, false);
      }

      if (executionNode.error != null) {
        throw RuntimeException(executionNode.error!);
      }

      return (executionNode.result, true);
    } finally {
      // Clean up any temporary state if needed in the future
      runtime.mainThread.executionStack.clear();
      runtime.mainThread.clearBreakTargets();
      runtime.mainThread.clearReturnTargets();
    }
  }

  static ExecutionNode? createExecutionNode(
    ParseTree parseTree,
    Thread thread,
    Scope scope,
  ) {
    if (parseTree.symbol == Symbols.nullLiteral) {
      return AprioriExecutionNode(null, thread: thread, scope: scope);
    }

    ExecutionNode? executionNode = tryCreateProgramExecutionNode(
      parseTree,
      thread,
      scope,
    );
    if (executionNode != null) {
      return executionNode;
    }

    executionNode = tryCreateTerminalExecutionNode(parseTree, thread, scope);
    if (executionNode != null) {
      return executionNode;
    }

    executionNode = tryCreateUnaryExecutionNode(parseTree, thread, scope);
    if (executionNode != null) {
      return executionNode;
    }

    executionNode = tryCreateIfStatementExecutionNode(parseTree, thread, scope);
    if (executionNode != null) {
      return executionNode;
    }

    executionNode = tryCreateWhileLoopExecutionNode(parseTree, thread, scope);
    if (executionNode != null) {
      return executionNode;
    }

    executionNode = tryCreateRepeatUntilLoopExecutionNode(
      parseTree,
      thread,
      scope,
    );
    if (executionNode != null) {
      return executionNode;
    }

    executionNode = tryCreateForLoopExecutionNode(parseTree, thread, scope);
    if (executionNode != null) {
      return executionNode;
    }

    executionNode = tryCreateBreakStatementExecutionNode(
      parseTree,
      thread,
      scope,
    );
    if (executionNode != null) {
      return executionNode;
    }

    executionNode = tryCreateContinueStatementExecutionNode(
      parseTree,
      thread,
      scope,
    );
    if (executionNode != null) {
      return executionNode;
    }

    executionNode = tryCreateReturnStatementExecutionNode(
      parseTree,
      thread,
      scope,
    );
    if (executionNode != null) {
      return executionNode;
    }

    executionNode = tryCreateCompoundStatementExecutionNode(
      parseTree,
      thread,
      scope,
    );
    if (executionNode != null) {
      return executionNode;
    }

    if (parseTree.children.length < 2) {
      return AprioriExecutionNode(double.nan, thread: thread, scope: scope);
    }

    if (parseTree.symbol == Symbols.memberAccess) {
      return MemberAccessExecutionNode(parseTree, thread: thread, scope: scope);
    }

    executionNode = tryCreateLambdaExpressionExecutionNode(
      parseTree,
      thread,
      scope,
    );
    if (executionNode != null) {
      return executionNode;
    }

    executionNode = tryCreateAssignmentExecutionNode(parseTree, thread, scope);
    if (executionNode != null) {
      return executionNode;
    }

    return createBinaryOperatorExecutionNode(parseTree, thread, scope);
  }

  static ExecutionNode? createBinaryOperatorExecutionNode(
    ParseTree parseTree,
    Thread thread,
    Scope scope,
  ) {
    var lhs = parseTree.children[0];
    var rhs = parseTree.children[1];
    switch (parseTree.symbol) {
      case Symbols.inOp:
        return InExecutionNode(lhs, rhs, thread: thread, scope: scope);
      case Symbols.pow:
        return ExponentiationExecutionNode(
          lhs,
          rhs,
          thread: thread,
          scope: scope,
        );
      case Symbols.mul:
        return MultiplicationExecutionNode(
          lhs,
          rhs,
          thread: thread,
          scope: scope,
        );
      case Symbols.div:
        return DivisionExecutionNode(lhs, rhs, thread: thread, scope: scope);
      case Symbols.mod:
        return ModulusExecutionNode(lhs, rhs, thread: thread, scope: scope);
      case Symbols.add:
        return AdditionExecutionNode(lhs, rhs, thread: thread, scope: scope);
      case Symbols.sub:
        return SubtractionExecutionNode(lhs, rhs, thread: thread, scope: scope);
      case Symbols.lt:
        return LessThanExecutionNode(lhs, rhs, thread: thread, scope: scope);
      case Symbols.ltEq:
        return LessThanOrEqualExecutionNode(
          lhs,
          rhs,
          thread: thread,
          scope: scope,
        );
      case Symbols.gt:
        return GreaterThanExecutionNode(lhs, rhs, thread: thread, scope: scope);
      case Symbols.gtEq:
        return GreaterThanOrEqualExecutionNode(
          lhs,
          rhs,
          thread: thread,
          scope: scope,
        );
      case Symbols.eq:
        return EqualityExecutionNode(lhs, rhs, thread: thread, scope: scope);
      case Symbols.neq:
        return NotEqualityExecutionNode(lhs, rhs, thread: thread, scope: scope);
      case Symbols.match:
        return MatchExecutionNode(lhs, rhs, thread: thread, scope: scope);
      case Symbols.notMatch:
        return NotMatchExecutionNode(lhs, rhs, thread: thread, scope: scope);
      case Symbols.and:
        return AndExecutionNode(lhs, rhs, thread: thread, scope: scope);
      case Symbols.or:
        return OrExecutionNode(lhs, rhs, thread: thread, scope: scope);
      case Symbols.xor:
        return XorExecutionNode(lhs, rhs, thread: thread, scope: scope);
      default:
        return null;
    }
  }

  static ProgramExecutionNode? tryCreateProgramExecutionNode(
    ParseTree parseTree,
    Thread thread,
    Scope scope,
  ) {
    if (parseTree.symbol != Symbols.program) {
      return null;
    }
    return ProgramExecutionNode(parseTree, thread: thread, scope: scope);
  }

  static ExecutionNode? tryCreateTerminalExecutionNode(
    ParseTree parseTree,
    Thread thread,
    Scope scope,
  ) {
    switch (parseTree.symbol) {
      case Symbols.list:
        return ListLiteralNode(parseTree, thread: thread, scope: scope);
      case Symbols.tuple:
        return TupleLiteralNode(parseTree, thread: thread, scope: scope);
      case Symbols.map:
        return MapLiteralNode(parseTree, thread: thread, scope: scope);
      case Symbols.floatLiteral:
        return ConstantNode<double>(parseTree, thread: thread, scope: scope);
      case Symbols.integerLiteral:
        return ConstantNode<int>(parseTree, thread: thread, scope: scope);
      case Symbols.stringLiteral:
        return ConstantNode<String>(parseTree, thread: thread, scope: scope);
      case Symbols.identifier:
        return IdentifierExecutionNode(parseTree, thread: thread, scope: scope);
      default:
        return null;
    }
  }

  static bool isUnary(Symbols symbol) {
    return [
      Symbols.unaryMinus,
      Symbols.unaryPlus,
      Symbols.not,
    ].contains(symbol);
  }

  static ExecutionNode? tryCreateUnaryExecutionNode(
    ParseTree parseTree,
    Thread thread,
    Scope scope,
  ) {
    if (!isUnary(parseTree.symbol)) {
      return null;
    }

    switch (parseTree.symbol) {
      case Symbols.unaryMinus:
        // Unary minus
        return UnaryMinusExecutionNode(
          parseTree.children[0],
          thread: thread,
          scope: scope,
        );
      case Symbols.unaryPlus:
        // Unary plus evalautes to first child
        return Engine.createExecutionNode(parseTree.children[0], thread, scope);
      case Symbols.not:
        return NotExecutionNode(
          parseTree.children[0],
          thread: thread,
          scope: scope,
        );
      default:
        return null;
    }
  }

  static IfStatementExecutionNode? tryCreateIfStatementExecutionNode(
    ParseTree parseTree,
    Thread thread,
    Scope scope,
  ) {
    if (parseTree.symbol != Symbols.ifStatement) {
      return null;
    }
    return IfStatementExecutionNode(parseTree, thread: thread, scope: scope);
  }

  static WhileLoopExecutionNode? tryCreateWhileLoopExecutionNode(
    ParseTree parseTree,
    Thread thread,
    Scope scope,
  ) {
    if (parseTree.symbol != Symbols.whileLoop) {
      return null;
    }
    return WhileLoopExecutionNode(parseTree, thread: thread, scope: scope);
  }

  static RepeatUntilLoopExecutionNode? tryCreateRepeatUntilLoopExecutionNode(
    ParseTree parseTree,
    Thread thread,
    Scope scope,
  ) {
    if (parseTree.symbol != Symbols.repeatUntilLoop) {
      return null;
    }
    return RepeatUntilLoopExecutionNode(
      parseTree,
      thread: thread,
      scope: scope,
    );
  }

  static ForLoopExecutionNode? tryCreateForLoopExecutionNode(
    ParseTree parseTree,
    Thread thread,
    Scope scope,
  ) {
    if (parseTree.symbol != Symbols.forLoop) {
      return null;
    }
    return ForLoopExecutionNode(parseTree, thread: thread, scope: scope);
  }

  static BreakStatementExecutionNode? tryCreateBreakStatementExecutionNode(
    ParseTree parseTree,
    Thread thread,
    Scope scope,
  ) {
    if (parseTree.symbol != Symbols.breakStatement) {
      return null;
    }
    return BreakStatementExecutionNode(thread: thread, scope: scope);
  }

  static ContinueStatementExecutionNode?
  tryCreateContinueStatementExecutionNode(
    ParseTree parseTree,
    Thread thread,
    Scope scope,
  ) {
    if (parseTree.symbol != Symbols.continueStatement) {
      return null;
    }
    return ContinueStatementExecutionNode(thread: thread, scope: scope);
  }

  static ReturnStatementExecutionNode? tryCreateReturnStatementExecutionNode(
    ParseTree parseTree,
    Thread thread,
    Scope scope,
  ) {
    if (parseTree.symbol != Symbols.returnStatement) {
      return null;
    }
    return ReturnStatementExecutionNode(
      parseTree,
      thread: thread,
      scope: scope,
    );
  }

  static CompoundStatementExecutionNode?
  tryCreateCompoundStatementExecutionNode(
    ParseTree parseTree,
    Thread thread,
    Scope scope,
  ) {
    if (parseTree.symbol != Symbols.compoundStatement) {
      return null;
    }
    return CompoundStatementExecutionNode(
      parseTree,
      thread: thread,
      scope: scope,
    );
  }

  static LambdaExpressionExecutionNode? tryCreateLambdaExpressionExecutionNode(
    ParseTree parseTree,
    Thread thread,
    Scope scope,
  ) {
    if (parseTree.symbol != Symbols.lambdaExpression) {
      return null;
    }
    return LambdaExpressionExecutionNode(
      "anonymous",
      parseTree,
      thread: thread,
      scope: scope,
    );
  }

  static AssignmentExecutionNode? tryCreateAssignmentExecutionNode(
    ParseTree parseTree,
    Thread thread,
    Scope scope,
  ) {
    if (parseTree.symbol != Symbols.assignment) {
      return null;
    }
    return AssignmentExecutionNode(parseTree, thread: thread, scope: scope);
  }
}
