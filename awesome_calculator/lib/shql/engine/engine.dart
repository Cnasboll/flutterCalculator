import 'dart:core';
import 'dart:math';

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
import 'package:awesome_calculator/shql/execution/constant_node.dart';
import 'package:awesome_calculator/shql/execution/execution_node.dart';
import 'package:awesome_calculator/shql/execution/artithmetic/exponentiation_execution_node.dart';
import 'package:awesome_calculator/shql/execution/identifier_node.dart';
import 'package:awesome_calculator/shql/execution/lambdas/function_definition_execution_node.dart';
import 'package:awesome_calculator/shql/execution/list_literal_node.dart';
import 'package:awesome_calculator/shql/execution/member_access_execution_node.dart';
import 'package:awesome_calculator/shql/execution/pattern/in_execution_node.dart';
import 'package:awesome_calculator/shql/execution/pattern/match_execution_node.dart';
import 'package:awesome_calculator/shql/execution/pattern/not_match_execution_node.dart';
import 'package:awesome_calculator/shql/execution/relational/equality_execution_node.dart';
import 'package:awesome_calculator/shql/execution/relational/greater_than_execution_node.dart';
import 'package:awesome_calculator/shql/execution/relational/greater_than_or_equal_execution_node.dart';
import 'package:awesome_calculator/shql/execution/relational/less_than_execution_node.dart';
import 'package:awesome_calculator/shql/execution/relational/less_than_or_equal_execution_node.dart';
import 'package:awesome_calculator/shql/execution/relational/not_equality_execution_node.dart';
import 'package:awesome_calculator/shql/parser/constants_set.dart';
import 'package:awesome_calculator/shql/parser/lookahead_iterator.dart';
import 'package:awesome_calculator/shql/parser/parse_tree.dart';
import 'package:awesome_calculator/shql/parser/parser.dart';
import 'package:awesome_calculator/shql/tokenizer/token.dart';
import 'package:awesome_calculator/shql/tokenizer/tokenizer.dart';

class RuntimeException implements Exception {
  final String message;

  RuntimeException(this.message);

  @override
  String toString() => 'RuntimeException: $message';
}

class Engine {
  static dynamic calculate(String expression, {ConstantsSet? constantsSet}) {
    var v = Tokenizer.tokenize(expression).toList();
    constantsSet ??= prepareConstantsSet();

    var tokenEnumerator = v.lookahead();

    List<ParseTree> p = [];
    while (tokenEnumerator.hasNext) {
      if (p.isNotEmpty) {
        if (tokenEnumerator.peek().tokenType != TokenTypes.semiColon) {
          throw RuntimeException(
            'Unexpcted token "${tokenEnumerator.next().lexeme}" after parsing expression.',
          );
        }
        // Consume the semicolon
        tokenEnumerator.next();
      }

      if (!tokenEnumerator.hasNext) {
        break;
      }
      p.add(Parser.parse(tokenEnumerator, constantsSet));
    }
    switch (p.length) {
      case 0:
        return null;
      case 1:
        return evaluate(p.first, constantsSet);
      default:
        dynamic lastResult;
        for (var tree in p) {
          lastResult = evaluate(tree, constantsSet);
        }
        return lastResult;
    }
  }

  static ConstantsSet prepareConstantsSet() {
    var constantsSet = ConstantsSet();

    // Register mathematical constants
    for (var entry in _intConstants.entries) {
      constantsSet.constants.register(
        entry.value,
        constantsSet.identifiers.include(entry.key),
      );
    }

    for (var entry in _doubleConstants.entries) {
      constantsSet.constants.register(
        entry.value,
        constantsSet.identifiers.include(entry.key),
      );
    }

    // Register mathematical functions
    for (var entry in unaryFunctions.entries) {
      constantsSet.identifiers.include(entry.key);
    }
    for (var entry in binaryFunctions.entries) {
      constantsSet.identifiers.include(entry.key);
    }
    return constantsSet;
  }

  static dynamic evaluate(ParseTree parseTree, ConstantsSet constantsSet) {
    var executionNode = createExecutionNode(parseTree);
    if (executionNode == null) {
      throw RuntimeException('Failed to create execution node.');
    }

    while (!executionNode.tick(constantsSet)) {}

    if (executionNode.error != null) {
      throw RuntimeException(executionNode.error!);
    }

    return executionNode.result;
  }

  static ExecutionNode? createExecutionNode(ParseTree parseTree) {
    if (parseTree.symbol == Symbols.nullLiteral) {
      return AprioriExecutionNode(null);
    }

    var executionNode = tryCreateTerminalExecutionNode(parseTree);
    if (executionNode != null) {
      return executionNode;
    }

    executionNode = tryCreateUnaryExecutionNode(parseTree);
    if (executionNode != null) {
      return executionNode;
    }

    if (parseTree.children.length < 2) {
      return AprioriExecutionNode(double.nan);
    }

    if (parseTree.symbol == Symbols.memberAccess) {
      return MemberAccessExecutionNode(parseTree);
    }

    if (parseTree.symbol == Symbols.functionDefinition) {
      return FunctionDefinitionExecutionNode(parseTree);
    }

    return createBinaryOperatorExecutionNode(parseTree);
  }

  static ExecutionNode? createBinaryOperatorExecutionNode(ParseTree parseTree) {
    var lhs = createExecutionNode(parseTree.children[0]);
    var rhs = createExecutionNode(parseTree.children[1]);
    switch (parseTree.symbol) {
      case Symbols.assignment:
        return AssignmentExecutionNode(lhs!, rhs!);
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

  static ExecutionNode? tryCreateTerminalExecutionNode(ParseTree parseTree) {
    switch (parseTree.symbol) {
      case Symbols.list:
        return ListLiteralNode(parseTree);
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

  static final Map<String, int> _intConstants = {
    "ANSWER": 42,
    "TRUE": 1,
    "FALSE": 0,
  };

  static final Map<String, double> _doubleConstants = {
    "E": e,
    "LN10": ln10,
    "LN2": ln2,
    "LOG2E": log2e,
    "LOG10E": log10e,
    "PI": pi,
    "SQRT1_2": sqrt1_2,
    "SQRT2": sqrt2,
    "AVOGADRO": 6.0221408e+23,
  };

  static final Map<String, dynamic Function(dynamic)> unaryFunctions = {
    "SIN": (a) => sin(a),
    "COS": (a) => cos(a),
    "TAN": (a) => tan(a),
    "ACOS": (a) => acos(a),
    "ASIN": (a) => asin(a),
    "ATAN": (a) => atan(a),
    "SQRT": (a) => sqrt(a),
    "EXP": (a) => exp(a),
    "LOG": (a) => log(a),
    "LOWERCASE": (a) => a.toString().toLowerCase(),
    "UPPERCASE": (a) => a.toString().toUpperCase(),
  };

  static final Map<String, dynamic Function(dynamic, dynamic)> binaryFunctions =
      {
        "MIN": (a, b) => min(a, b),
        "MAX": (a, b) => max(a, b),
        "ATAN2": (a, b) => atan2(a, b),
        "POW": (a, b) => pow(a, b),
      };
}
