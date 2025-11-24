import 'dart:core';
import 'dart:math';

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
    var p = Parser.parse(tokenEnumerator, constantsSet);

    if (tokenEnumerator.hasNext) {
      throw RuntimeException(
        'Unexpcted token "${tokenEnumerator.next().lexeme}" after parsing expression.',
      );
    }
    return evaluate(p, constantsSet);
  }

  static ConstantsSet prepareConstantsSet() {
    var constantsSet = ConstantsSet();

    // Register mathematical constants
    for (var entry in _int_constants.entries) {
      constantsSet.constants.register(
        entry.value,
        constantsSet.identifiers.include(entry.key),
      );
    }

    for (var entry in _double_constants.entries) {
      constantsSet.constants.register(
        entry.value,
        constantsSet.identifiers.include(entry.key),
      );
    }

    // Register mathematical functions
    for (var entry in _unaryFunctions.entries) {
      constantsSet.identifiers.include(entry.key);
    }
    for (var entry in _binaryFunctions.entries) {
      constantsSet.identifiers.include(entry.key);
    }
    return constantsSet;
  }

  static dynamic evaluate(ParseTree parseTree, ConstantsSet constantsSet) {
    if (parseTree.symbol == Symbols.nullLiteral) {
      return null;
    }
    
    var result = evaluateTerminal(parseTree, constantsSet);
    if (result != null) {
      return result;
    }
    result = evaluateUnary(parseTree, constantsSet);
    if (result != null) {
      return result;
    }

    if (parseTree.children.length < 2) {
      return double.nan;
    }

    if (parseTree.symbol == Symbols.memberAccess) {
      return evaluateMemberAccess(parseTree, constantsSet);
    }

    return evaluateBinaryOperator(
      parseTree.symbol,
      evaluate(parseTree.children[0], constantsSet),
      evaluate(parseTree.children[1], constantsSet),
    );
  }

  static dynamic evaluateBinaryOperator(
    Symbols symbol,
    dynamic argument1,
    argument2,
  ) {
    final oneIsNull = [argument1, argument2].contains(null);
    switch (symbol) {
      case Symbols.inOp:
        {
          if (argument2 is List) {
            return argument2.contains(argument1) ? 1 : 0;
          }
          var lhs = argument1 is String ? argument1 : argument1.toString();
          var rhs = argument2 is String ? argument2 : argument2.toString();
          return rhs.contains(lhs) ? 1 : 0;
        }
      case Symbols.add:
        {
          if (oneIsNull) {
            return null;
          }
          return argument1 + argument2;
        }

      case Symbols.sub:
        {
          if (oneIsNull) {
            return null;
          }
          return argument1 - argument2;
        }

      case Symbols.div:
        {
          if (oneIsNull) {
            return null;
          }
          return argument1 / argument2;
        }

      case Symbols.eq:
        {
          return argument1 == argument2 ? 1 : 0;
        }

      case Symbols.match:
      case Symbols.notMatch:
        {
          if (oneIsNull) {
            return 0;
          }

          var negated = symbol == Symbols.notMatch;
          var regex = RegExp(argument2.toString(), caseSensitive: false);
          var match = regex.hasMatch(argument1.toString());
          return negated ? (match ? 0 : 1) : (match ? 1 : 0);
        }

      case Symbols.gt:
        {
          if (oneIsNull) {
            return 0;
          }
          return argument1 > argument2 ? 1 : 0;
        }

      case Symbols.gtEq:
        {
          if (oneIsNull) {
            return 0;
          }
          return argument1 >= argument2 ? 1 : 0;
        }
      case Symbols.lt:
        {
          if (oneIsNull) {
            return 0;
          }
          return argument1 < argument2 ? 1 : 0;
        }
      case Symbols.ltEq:
        {
          if (oneIsNull) {
            return 0;
          }
          return argument1 <= argument2 ? 1 : 0;
        }
      case Symbols.mod:
        {
          if (oneIsNull) {
            return null;
          }
          return argument1 % argument2;
        }
      case Symbols.mul:
        {
          if (oneIsNull) {
            return null;
          }
          return argument1 * argument2;
        }
      case Symbols.neq:
        return argument1 != argument2 ? 1 : 0;

      case Symbols.and:
        return (argument1 != 0) && (argument2 != 0) ? 1 : 0;
      case Symbols.or:
        return (argument1 != 0) || (argument2 != 0) ? 1 : 0;
      case Symbols.xor:
        return (argument1 != 0) != (argument2 != 0) ? 1 : 0;
      default:
        return double.nan;
    }
  }

  static dynamic evaluateTerminal(
    ParseTree parseTree,
    ConstantsSet constantsSet,
  ) {
    switch (parseTree.symbol) {
      case Symbols.list:
        return parseTree.children
            .map((child) => evaluate(child, constantsSet))
            .toList();
      case Symbols.floatLiteral:
        return constantsSet.constants.constants[parseTree.qualifier!] as double;
      case Symbols.integerLiteral:
        return constantsSet.constants.constants[parseTree.qualifier!] as int;
      case Symbols.stringLiteral:
        return constantsSet.constants.constants[parseTree.qualifier!] as String;
      case Symbols.identifier:
        return evaluateIdentifier(parseTree, constantsSet);
      default:
        return null;
    }
  }

  static dynamic evaluateIdentifier(
    ParseTree parseTree,
    ConstantsSet constantsSet,
  ) {
    var identifier = constantsSet.identifiers.constants[parseTree.qualifier!];
    var (constant, index) = constantsSet.constants.getByIdentifier(
      parseTree.qualifier!,
    );
    if (constant != null || index != null) {
      if (parseTree.children.isNotEmpty) {
        var argumentCount = parseTree.children.length;
        if (argumentCount == 1) {
          return Engine.evaluateBinaryOperator(
            Symbols.mul,
            constant,
            evaluate(parseTree.children[0], constantsSet)
          );
        }
        throw RuntimeException(
          "Attempt to use constant $identifier as a function: ($argumentCount) argument(s) given.",
        );
      }
      return constant;
    }

    var unaryFunction = _unaryFunctions[identifier];
    if (unaryFunction != null) {
      if (parseTree.children.length != 1) {
        var argumentCount = parseTree.children.length;
        throw RuntimeException(
          "Function $identifier() takes 1 argument, $argumentCount given.",
        );
      }
      return unaryFunction(evaluate(parseTree.children.first, constantsSet));
    }

    var binaryFunction = _binaryFunctions[identifier];
    if (binaryFunction != null) {
      if (parseTree.children.length != 2) {
        var argumentCount = parseTree.children.length;
        throw RuntimeException(
          "Function $identifier() takes 2 arguments, $argumentCount given.",
        );
      }
      return binaryFunction(
        evaluate(parseTree.children[0], constantsSet),
        evaluate(parseTree.children[1], constantsSet),
      );
    }

    if (parseTree.children.isNotEmpty) {
      throw RuntimeException(
        'Unidentified identifier "$identifier" used as a function.',
      );
    }
    throw RuntimeException(
      '''Unidentified identifier "$identifier" used as a constant.

Hint: enclose strings in quotes, e.g.          name ~ "Batman"       rather than:     name ~ Batman

''',
    );
  }

  static bool isUnary(Symbols symbol) {
    return [
      Symbols.unaryMinus,
      Symbols.unaryPlus,
      Symbols.not,
    ].contains(symbol);
  }

  static dynamic evaluateMemberAccess(
    ParseTree parseTree,
    ConstantsSet constantsSet,
  ) {
    if (parseTree.children.length != 2) {
      throw RuntimeException('Member access must have exactly 2 children');
    }

    var leftChild = parseTree.children[0];
    var rightChild = parseTree.children[1];

    // Right side must always be an identifier
    if (rightChild.symbol != Symbols.identifier) {
      throw RuntimeException(
        'Right side of member access must be an identifier',
      );
    }

    ConstantsSet targetScope;

    if (leftChild.symbol == Symbols.identifier) {
      // Simple case: a.b
      targetScope = constantsSet.getSubModelScope(leftChild.qualifier!);
    } else if (leftChild.symbol == Symbols.memberAccess) {
      // Recursive case: a.b.c (where a.b is another memberAccess)
      // We need to resolve the left side to get the appropriate scope
      targetScope = _resolveMemberAccessToScope(leftChild, constantsSet);
    } else {
      throw RuntimeException(
        'Left side of member access must be an identifier or another member access',
      );
    }

    return evaluateIdentifier(rightChild, targetScope);
  }

  static ConstantsSet _resolveMemberAccessToScope(
    ParseTree memberAccessTree,
    ConstantsSet constantsSet,
  ) {
    if (memberAccessTree.symbol != Symbols.memberAccess) {
      throw RuntimeException('Expected member access parse tree');
    }

    var leftChild = memberAccessTree.children[0];
    var rightChild = memberAccessTree.children[1];

    if (rightChild.symbol != Symbols.identifier) {
      throw RuntimeException(
        'Right side of member access must be an identifier',
      );
    }

    ConstantsSet intermediateScope;

    if (leftChild.symbol == Symbols.identifier) {
      // Base case: a.b - get sub-scope of a
      intermediateScope = constantsSet.getSubModelScope(leftChild.qualifier!);
    } else if (leftChild.symbol == Symbols.memberAccess) {
      // Recursive case: resolve a.b first, then get its sub-scope
      intermediateScope = _resolveMemberAccessToScope(leftChild, constantsSet);
    } else {
      throw RuntimeException(
        'Left side of member access must be an identifier or another member access',
      );
    }

    // Now get the sub-scope of the right identifier within the intermediate scope
    return intermediateScope.getSubModelScope(rightChild.qualifier!);
  }

  static dynamic evaluateUnary(ParseTree parseTree, ConstantsSet constantsSet) {
    if (!isUnary(parseTree.symbol)) {
      return null;
    }
    if (parseTree.children.isEmpty) {
      return double.nan;
    }

    var arg = evaluate(parseTree.children.first, constantsSet);
    if (arg == null) {
      return double.nan;
    }
    switch (parseTree.symbol) {
      case Symbols.unaryMinus:
        // Unary minus
        return -arg;
      case Symbols.unaryPlus:
        // Unary plus
        return arg;
      case Symbols.not:
        return arg == 0 ? 1 : 0;
      default:
        return null;
    }
  }

  static final Map<String, int> _int_constants = {
    "ANSWER": 42,
    "TRUE": 1,
    "FALSE": 0,
  };

  static final Map<String, double> _double_constants = {
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

  static final Map<String, dynamic Function(dynamic)> _unaryFunctions = {
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

  static final Map<String, dynamic Function(dynamic, dynamic)>
  _binaryFunctions = {
    "MIN": (a, b) => min(a, b),
    "MAX": (a, b) => max(a, b),
    "ATAN2": (a, b) => atan2(a, b),
    "POW": (a, b) => pow(a, b),
  };
}
