import 'dart:core';

import 'package:awesome_calculator/shql/engine/cancellation_token.dart';
import 'package:awesome_calculator/shql/execution/apriori_execution_node.dart';
import 'package:awesome_calculator/shql/execution/artithmetic/addition_execution_node.dart';
import 'package:awesome_calculator/shql/execution/artithmetic/division_execution_node.dart';
import 'package:awesome_calculator/shql/execution/artithmetic/modulus_execution_node.dart';
import 'package:awesome_calculator/shql/execution/artithmetic/multiplication_execution_node.dart';
import 'package:awesome_calculator/shql/execution/artithmetic/subtraction_execution_node.dart';
import 'package:awesome_calculator/shql/execution/artithmetic/unary_minus_execution_node.dart';
import 'package:awesome_calculator/shql/execution/assignment_execution_node.dart';
import 'package:awesome_calculator/shql/execution/boolean/and_execution_node.dart';
import 'package:awesome_calculator/shql/execution/boolean/not_execution_node.dart';
import 'package:awesome_calculator/shql/execution/boolean/or_execution_node.dart';
import 'package:awesome_calculator/shql/execution/boolean/xor_execution_node.dart';
import 'package:awesome_calculator/shql/execution/break_statement_execution_node.dart';
import 'package:awesome_calculator/shql/execution/compound_statement_execution_node.dart';
import 'package:awesome_calculator/shql/execution/constant_node.dart';
import 'package:awesome_calculator/shql/execution/continue_statement_execution_node.dart';
import 'package:awesome_calculator/shql/execution/execution_node.dart';
import 'package:awesome_calculator/shql/execution/artithmetic/exponentiation_execution_node.dart';
import 'package:awesome_calculator/shql/execution/for_loop_execution_node.dart';
import 'package:awesome_calculator/shql/execution/identifier_exeuction_node.dart';
import 'package:awesome_calculator/shql/execution/if_statement_execution_node.dart';
import 'package:awesome_calculator/shql/execution/lambdas/lambda_expression_execution_node.dart';
import 'package:awesome_calculator/shql/execution/list_literal_node.dart';
import 'package:awesome_calculator/shql/execution/map_literal_node.dart';
import 'package:awesome_calculator/shql/execution/member_access_execution_node.dart';
import 'package:awesome_calculator/shql/execution/pattern/in_execution_node.dart';
import 'package:awesome_calculator/shql/execution/pattern/match_execution_node.dart';
import 'package:awesome_calculator/shql/execution/pattern/not_match_execution_node.dart';
import 'package:awesome_calculator/shql/execution/program_execution_node.dart';
import 'package:awesome_calculator/shql/execution/relational/equality_execution_node.dart';
import 'package:awesome_calculator/shql/execution/relational/greater_than_execution_node.dart';
import 'package:awesome_calculator/shql/execution/relational/greater_than_or_equal_execution_node.dart';
import 'package:awesome_calculator/shql/execution/relational/less_than_execution_node.dart';
import 'package:awesome_calculator/shql/execution/relational/less_than_or_equal_execution_node.dart';
import 'package:awesome_calculator/shql/execution/relational/not_equality_execution_node.dart';
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
      var executionNode = createExecutionNode(parseTree);
      if (executionNode == null) {
        throw RuntimeException('Failed to create execution node.');
      }

      while ((cancellationToken == null || !await cancellationToken.check()) &&
          !await executionNode.tick(runtime, cancellationToken)) {}

      if (executionNode.error != null) {
        throw RuntimeException(executionNode.error!);
      }

      return executionNode.result;
    } finally {
      // Clean up any temporary state if needed in the future
      runtime.popChildScopes();
      runtime.clearBreakTargets();
      runtime.clearReturnTargets();
    }
  }

  static Future<(dynamic, bool)> _calculate(
    ParseTree parseTree,
    Runtime runtime,
  ) async {
    try {
      var executionNode = createExecutionNode(parseTree);
      if (executionNode == null) {
        throw RuntimeException('Failed to create execution node.');
      }

      if (!await executionNode.tick(runtime)) {
        return (null, false);
      }

      if (executionNode.error != null) {
        throw RuntimeException(executionNode.error!);
      }

      return (executionNode.result, true);
    } finally {
      // Clean up any temporary state if needed in the future
      runtime.popChildScopes();
      runtime.clearBreakTargets();
      runtime.clearReturnTargets();
    }
  }

  static ExecutionNode? createExecutionNode(ParseTree parseTree) {
    if (parseTree.symbol == Symbols.nullLiteral) {
      return AprioriExecutionNode(null);
    }

    ExecutionNode? executionNode = tryCreateProgramExecutionNode(parseTree);
    if (executionNode != null) {
      return executionNode;
    }

    executionNode = tryCreateTerminalExecutionNode(parseTree);
    if (executionNode != null) {
      return executionNode;
    }

    executionNode = tryCreateUnaryExecutionNode(parseTree);
    if (executionNode != null) {
      return executionNode;
    }

    executionNode = tryCreateIfStatementExecutionNode(parseTree);
    if (executionNode != null) {
      return executionNode;
    }

    executionNode = tryCreateWhileLoopExecutionNode(parseTree);
    if (executionNode != null) {
      return executionNode;
    }

    executionNode = tryCreateRepeatUntilLoopExecutionNode(parseTree);
    if (executionNode != null) {
      return executionNode;
    }

    executionNode = tryCreateForLoopExecutionNode(parseTree);
    if (executionNode != null) {
      return executionNode;
    }

    executionNode = tryCreateBreakStatementExecutionNode(parseTree);
    if (executionNode != null) {
      return executionNode;
    }

    executionNode = tryCreateContinueStatementExecutionNode(parseTree);
    if (executionNode != null) {
      return executionNode;
    }

    executionNode = tryCreateReturnStatementExecutionNode(parseTree);
    if (executionNode != null) {
      return executionNode;
    }

    executionNode = tryCreateCompoundStatementExecutionNode(parseTree);
    if (executionNode != null) {
      return executionNode;
    }

    if (parseTree.children.length < 2) {
      return AprioriExecutionNode(double.nan);
    }

    if (parseTree.symbol == Symbols.memberAccess) {
      return MemberAccessExecutionNode(parseTree);
    }

    executionNode = tryCreateLambdaExpressionExecutionNode(parseTree);
    if (executionNode != null) {
      return executionNode;
    }

    executionNode = tryCreateAssignmentExecutionNode(parseTree);
    if (executionNode != null) {
      return executionNode;
    }

    return createBinaryOperatorExecutionNode(parseTree);
  }

  static ExecutionNode? createBinaryOperatorExecutionNode(ParseTree parseTree) {
    var lhs = createExecutionNode(parseTree.children[0]);
    var rhs = createExecutionNode(parseTree.children[1]);
    switch (parseTree.symbol) {
      case Symbols.inOp:
        return InExecutionNode(lhs!, rhs!);
      case Symbols.pow:
        return ExponentiationExecutionNode(lhs!, rhs!);
      case Symbols.mul:
        return MultiplicationExecutionNode(lhs!, rhs!);
      case Symbols.div:
        return DivisionExecutionNode(lhs!, rhs!);
      case Symbols.mod:
        return ModulusExecutionNode(lhs!, rhs!);
      case Symbols.add:
        return AdditionExecutionNode(lhs!, rhs!);
      case Symbols.sub:
        return SubtractionExecutionNode(lhs!, rhs!);
      case Symbols.lt:
        return LessThanExecutionNode(lhs!, rhs!);
      case Symbols.ltEq:
        return LessThanOrEqualExecutionNode(lhs!, rhs!);
      case Symbols.gt:
        return GreaterThanExecutionNode(lhs!, rhs!);
      case Symbols.gtEq:
        return GreaterThanOrEqualExecutionNode(lhs!, rhs!);
      case Symbols.eq:
        return EqualityExecutionNode(lhs!, rhs!);
      case Symbols.neq:
        return NotEqualityExecutionNode(lhs!, rhs!);
      case Symbols.match:
        return MatchExecutionNode(lhs!, rhs!);
      case Symbols.notMatch:
        return NotMatchExecutionNode(lhs!, rhs!);
      case Symbols.and:
        return AndExecutionNode(lhs!, rhs!);
      case Symbols.or:
        return OrExecutionNode(lhs!, rhs!);
      case Symbols.xor:
        return XorExecutionNode(lhs!, rhs!);
      default:
        return null;
    }
  }

  static ProgramExecutionNode? tryCreateProgramExecutionNode(
    ParseTree parseTree,
  ) {
    if (parseTree.symbol != Symbols.program) {
      return null;
    }
    return ProgramExecutionNode(parseTree);
  }

  static ExecutionNode? tryCreateTerminalExecutionNode(ParseTree parseTree) {
    switch (parseTree.symbol) {
      case Symbols.list:
        return ListLiteralNode(parseTree);
      case Symbols.tuple:
        return TupleLiteralNode(parseTree);
      case Symbols.map:
        return MapLiteralNode(parseTree);
      case Symbols.floatLiteral:
        return ConstantNode<double>(parseTree);
      case Symbols.integerLiteral:
        return ConstantNode<int>(parseTree);
      case Symbols.stringLiteral:
        return ConstantNode<String>(parseTree);
      case Symbols.identifier:
        return IdentifierExecutionNode(parseTree);
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

  static ExecutionNode? tryCreateUnaryExecutionNode(ParseTree parseTree) {
    if (!isUnary(parseTree.symbol)) {
      return null;
    }
    if (parseTree.children.isEmpty) {
      return AprioriExecutionNode(double.nan);
    }

    var operand = createExecutionNode(parseTree.children.first);
    if (operand == null) {
      return AprioriExecutionNode(double.nan);
    }
    switch (parseTree.symbol) {
      case Symbols.unaryMinus:
        // Unary minus
        return UnaryMinusExecutionNode(operand);
      case Symbols.unaryPlus:
        // Unary plus
        return operand;
      case Symbols.not:
        return NotExecutionNode(operand);
      default:
        return null;
    }
  }

  static IfStatementExecutionNode? tryCreateIfStatementExecutionNode(
    ParseTree parseTree,
  ) {
    if (parseTree.symbol != Symbols.ifStatement) {
      return null;
    }
    return IfStatementExecutionNode(parseTree);
  }

  static WhileLoopExecutionNode? tryCreateWhileLoopExecutionNode(
    ParseTree parseTree,
  ) {
    if (parseTree.symbol != Symbols.whileLoop) {
      return null;
    }
    return WhileLoopExecutionNode(parseTree);
  }

  static RepeatUntilLoopExecutionNode? tryCreateRepeatUntilLoopExecutionNode(
    ParseTree parseTree,
  ) {
    if (parseTree.symbol != Symbols.repeatUntilLoop) {
      return null;
    }
    return RepeatUntilLoopExecutionNode(parseTree);
  }

  static ForLoopExecutionNode? tryCreateForLoopExecutionNode(
    ParseTree parseTree,
  ) {
    if (parseTree.symbol != Symbols.forLoop) {
      return null;
    }
    return ForLoopExecutionNode(parseTree);
  }

  static BreakStatementExecutionNode? tryCreateBreakStatementExecutionNode(
    ParseTree parseTree,
  ) {
    if (parseTree.symbol != Symbols.breakStatement) {
      return null;
    }
    return BreakStatementExecutionNode();
  }

  static ContinueStatementExecutionNode?
  tryCreateContinueStatementExecutionNode(ParseTree parseTree) {
    if (parseTree.symbol != Symbols.continueStatement) {
      return null;
    }
    return ContinueStatementExecutionNode();
  }

  static ReturnStatementExecutionNode? tryCreateReturnStatementExecutionNode(
    ParseTree parseTree,
  ) {
    if (parseTree.symbol != Symbols.returnStatement) {
      return null;
    }
    return ReturnStatementExecutionNode(parseTree);
  }

  static CompoundStatementExecutionNode?
  tryCreateCompoundStatementExecutionNode(ParseTree parseTree) {
    if (parseTree.symbol != Symbols.compoundStatement) {
      return null;
    }
    return CompoundStatementExecutionNode(parseTree);
  }

  static LambdaExpressionExecutionNode? tryCreateLambdaExpressionExecutionNode(
    ParseTree parseTree,
  ) {
    if (parseTree.symbol != Symbols.lambdaExpression) {
      return null;
    }
    return LambdaExpressionExecutionNode("anonymous", parseTree);
  }

  static AssignmentExecutionNode? tryCreateAssignmentExecutionNode(
    ParseTree parseTree,
  ) {
    if (parseTree.symbol != Symbols.assignment) {
      return null;
    }
    return AssignmentExecutionNode(parseTree);
  }
}
