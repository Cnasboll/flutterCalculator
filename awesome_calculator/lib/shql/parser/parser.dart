import 'package:awesome_calculator/shql/parser/constants_set.dart';
import 'package:awesome_calculator/shql/parser/parse_tree.dart';
import 'package:awesome_calculator/shql/parser/lookahead_iterator.dart';
import 'package:awesome_calculator/shql/tokenizer/string_escaper.dart';
import 'package:awesome_calculator/shql/tokenizer/token.dart';

class ParseException implements Exception {
  final String message;

  ParseException(this.message);

  @override
  String toString() => 'ParseException: $message';
}

class Parser {
  static ParseTree parse(
    LookaheadIterator<Token> tokenEnumerator,
    ConstantsSet constantsSet,
  ) {
    if (tokenEnumerator.peek().keyword == Keywords.fnKeyword) {
      // Function definition
      tokenEnumerator.next();
      return parseFunctionDefinition(tokenEnumerator, constantsSet);
    }
    return parseExpression(tokenEnumerator, constantsSet);
  }

  static ParseTree parseFunctionDefinition(
    LookaheadIterator<Token> tokenEnumerator,
    ConstantsSet constantsSet,
  ) {
    // Function definition
    tokenEnumerator.next();
    var functionName = parse(tokenEnumerator, constantsSet);
    if (functionName.symbol != Symbols.identifier) {
      throw ParseException(
        'Expected function name identifier after fn keyword.',
      );
    }
    // Parse argument list
    var arguments = parseFunctionArgumentList(
      tokenEnumerator,
      constantsSet,
      constantsSet.identifiers.constants[functionName.qualifier!],
    );
    // Now parse the function body
    var body = parse(tokenEnumerator, constantsSet);
    return ParseTree.withChildren(Symbols.functionDefinition, [
      functionName,
      arguments,
      body,
    ]);
  }

  static ParseTree parseFunctionArgumentList(
    LookaheadIterator<Token> tokenEnumerator,
    ConstantsSet constantsSet,
    String functionName,
  ) {
    List<ParseTree> arguments = [];
    var result = ParseTree(Symbols.functionArgumentList, arguments);

    if (tokenEnumerator.hasNext &&
        tokenEnumerator.peek().tokenType == TokenTypes.lPar) {
      // Consume the parenthsis
      tokenEnumerator.next();
      // Proceed to next token
      if (tokenEnumerator.peek().tokenType == TokenTypes.rPar) {
        // Empty argument list
        // Consume the parenthsis
        tokenEnumerator.next();
        return result;
      }
      for (;;) {
        var argument = parse(tokenEnumerator, constantsSet);
        if (argument.symbol != Symbols.identifier) {
          throw ParseException(
            "Expected identifier in argument list of function $functionName.",
          );
        }
        arguments.add(argument);

        if (!tokenEnumerator.hasNext) {
          throw ParseException(
            "End of stream when consuming arguments for function $functionName()",
          );
        }

        tokenEnumerator.next();

        if (tokenEnumerator.current.tokenType == TokenTypes.rPar) {
          break;
        }

        if (tokenEnumerator.current.tokenType != TokenTypes.comma) {
          var n = arguments.length;
          throw ParseException(
            "Expected comma or right parenthesis following $n:th argument for to function declaration $functionName()",
          );
        }
      }
    }
    return result;
  }

  static ParseTree parseExpression(
    LookaheadIterator<Token> tokenEnumerator,
    ConstantsSet constantsSet,
  ) {
    var operandStack = <ParseTree>[];
    var operatorStack = <Token>[];

    do {
      if (!tokenEnumerator.hasNext) {
        throw ParseException(
          "Unexpected End of token stream while expecting operand.",
        );
      }
      tokenEnumerator.next();

      operandStack.add(parseOperand(tokenEnumerator, constantsSet));

      // If we find a left parenthesis here, consider this a multiplication!
      if (tokenEnumerator.hasNext &&
          tokenEnumerator.peek().tokenType == TokenTypes.lPar) {
        operatorStack.add(Token.parser(TokenTypes.mul, "*"));
      } else if (tryConsumeOperator(tokenEnumerator)) {
        while (operatorStack.isNotEmpty &&
            !tokenEnumerator.current.takesPrecedence(operatorStack.last)) {
          popOperatorStack(tokenEnumerator, operandStack, operatorStack);
        }
        operatorStack.add(tokenEnumerator.current);
      } else {
        // No more operators.
        while (operatorStack.isNotEmpty) {
          popOperatorStack(tokenEnumerator, operandStack, operatorStack);
        }
      }
    } while (operatorStack.isNotEmpty || operandStack.length > 1);

    return operandStack.removeLast();
  }

  static void popOperatorStack(
    LookaheadIterator<Token> tokenEnumerator,
    List<ParseTree> operandStack,
    List<Token> operatorStack,
  ) {
    Token operatorToken = operatorStack.removeLast();
    if (operandStack.length < 2) {
      var unexpectedLexeme = tokenEnumerator.peek().lexeme;
      var operatorLexeme = operatorStack.last.lexeme;
      throw ParseException(
        'Unexpected token "$unexpectedLexeme" when expecting operand for binary operator "$operatorLexeme".',
      );
    }
    var rhs = operandStack.removeLast();
    var lhs = operandStack.removeLast();
    operandStack.add(ParseTree(operatorToken.symbol, [lhs, rhs]));
  }

  static bool tryConsumeOperator(LookaheadIterator<Token> tokenEnumerator) {
    if (tokenEnumerator.hasNext && tokenEnumerator.peek().isOperator()) {
      tokenEnumerator.next();
      return true;
    }
    return false;
  }

  static ParseTree parseOperand(
    LookaheadIterator<Token> tokenEnumerator,
    ConstantsSet constantsSet, [
    bool allowSign = true,
  ]) {
    if (tokenEnumerator.current.symbol == Symbols.nullLiteral) {
      return ParseTree(Symbols.nullLiteral, []);
    }

    // If we find a plus or minus sign here, consider that a sign for the operand, then we recurse
    if (tokenEnumerator.current.symbol == Symbols.add) {
      tokenEnumerator.next();
      return ParseTree.withChildren(Symbols.unaryPlus, [
        parseOperand(tokenEnumerator, constantsSet, false),
      ]);
    }

    if (tokenEnumerator.current.symbol == Symbols.sub) {
      tokenEnumerator.next();
      return ParseTree.withChildren(Symbols.unaryMinus, [
        parseOperand(tokenEnumerator, constantsSet, false),
      ]);
    }

    if (tokenEnumerator.current.symbol == Symbols.not) {
      tokenEnumerator.next();
      return ParseTree.withChildren(Symbols.not, [
        parseOperand(tokenEnumerator, constantsSet),
      ]);
    }

    // If we find a left parenthesis, we recurse as that is the highest precedence
    if (tokenEnumerator.current.tokenType == TokenTypes.lPar) {
      var parseTree = parse(tokenEnumerator, constantsSet);
      consume(tokenEnumerator, TokenTypes.rPar, ")");
      return parseTree;
    }

    if (tokenEnumerator.current.tokenType == TokenTypes.identifier) {
      String identifierName = tokenEnumerator.current.lexeme;
      return ParseTree(
        Symbols.identifier,
        parseArgumentList(tokenEnumerator, constantsSet, identifierName),
        constantsSet.identifiers.include(identifierName.toUpperCase()),
      );
    }

    if (tokenEnumerator.current.tokenType == TokenTypes.lBrack) {
      return ParseTree(Symbols.list, parseList(tokenEnumerator, constantsSet));
    }

    String currentLexeme = tokenEnumerator.current.lexeme;

    switch (tokenEnumerator.current.literalType) {
      case LiteralTypes.integerLiteral:
        return ParseTree.withQualifier(
          Symbols.integerLiteral,
          constantsSet.includeConstant(
            int.parse(tokenEnumerator.current.lexeme),
          ),
        );
      case LiteralTypes.floatLiteral:
        return ParseTree.withQualifier(
          Symbols.floatLiteral,
          constantsSet.includeConstant(
            double.parse(tokenEnumerator.current.lexeme),
          ),
        );
      case LiteralTypes.doubleQuotedStringLiteral:
      case LiteralTypes.singleQuotedStringLiteral:
        return ParseTree.withQualifier(
          Symbols.stringLiteral,
          constantsSet.includeConstant(
            StringEscaper.unescape(tokenEnumerator.current.lexeme),
          ),
        );
      case LiteralTypes.doubleQuotedRawStringLiteral:
      case LiteralTypes.singleQuotedRawStringLiteral:
        return ParseTree.withQualifier(
          Symbols.stringLiteral,
          constantsSet.includeConstant(
            tokenEnumerator.current.lexeme.substring(
              2,
              tokenEnumerator.current.lexeme.length - 1,
            ),
          ),
        );
      default:
    }

    throw ParseException(
      'Unexpected token "$currentLexeme" when expecting operand.',
    );
  }

  static List<ParseTree> parseArgumentList(
    LookaheadIterator<Token> tokenEnumerator,
    ConstantsSet constantsSet,
    String functionName,
  ) {
    List<ParseTree> arguments = [];

    if (tokenEnumerator.hasNext &&
        tokenEnumerator.peek().tokenType == TokenTypes.lPar) {
      // Consume the parenthsis
      tokenEnumerator.next();
      // Proceed to next token
      if (tokenEnumerator.peek().tokenType == TokenTypes.rPar) {
        // Empty argument list
        // Consume the parenthsis
        tokenEnumerator.next();
        return arguments;
      }
      for (;;) {
        arguments.add(parse(tokenEnumerator, constantsSet));

        if (!tokenEnumerator.hasNext) {
          throw ParseException(
            "End of stream when consuming arguments for call to function $functionName()",
          );
        }

        tokenEnumerator.next();

        if (tokenEnumerator.current.tokenType == TokenTypes.rPar) {
          break;
        }

        if (tokenEnumerator.current.tokenType != TokenTypes.comma) {
          var n = arguments.length;
          throw ParseException(
            "Expected comma or right parenthesis following $n:th argument for call to function $functionName()",
          );
        }
      }
    }
    return arguments;
  }

  static List<ParseTree> parseList(
    LookaheadIterator<Token> tokenEnumerator,
    ConstantsSet constantsSet,
  ) {
    List<ParseTree> elements = [];

    // Proceed to next token
    if (tokenEnumerator.peek().tokenType == TokenTypes.rBrack) {
      // Empty list
      // Consume the bracket
      tokenEnumerator.next();
      return elements;
    }
    for (;;) {
      elements.add(parse(tokenEnumerator, constantsSet));

      if (!tokenEnumerator.hasNext) {
        throw ParseException("End of stream when consuming list");
      }

      tokenEnumerator.next();

      if (tokenEnumerator.current.tokenType == TokenTypes.rBrack) {
        break;
      }

      if (tokenEnumerator.current.tokenType != TokenTypes.comma) {
        var n = elements.length;
        throw ParseException(
          "Expected comma or right bracket following $n:th list element",
        );
      }
    }

    return elements;
  }

  static void consume(
    LookaheadIterator<Token> tokenEnumerator,
    TokenTypes expectedType,
    String expectedLexeme,
  ) {
    if (!tokenEnumerator.hasNext) {
      throw ParseException(
        "End of token stream when expecting '$expectedType'",
      );
    }
    var token = tokenEnumerator.next();
    if (token.tokenType != expectedType) {
      var actualLexeme = token.lexeme;
      throw ParseException(
        "Found token '$actualLexeme' when expecting '$expectedLexeme'",
      );
    }
  }
}
