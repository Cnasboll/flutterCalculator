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
    return parseExpression(tokenEnumerator, constantsSet);
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

      var brackets = tryParseBrackets(tokenEnumerator, constantsSet);
      if (brackets != null) {
        if (brackets.symbol == Symbols.tuple && brackets.children.length == 1) {
          operandStack.add(brackets.children[0]);
          // TODO: If we can parse a second operand here, we should consider this a multiplication
          // and push a multiplication operator to the operator stack
          // So we need a tryParseOperand that doesn't throw on failure and dosen't advance the enumerator
          // if no operand is found
          var (operand, _) = tryParseOperand(tokenEnumerator, constantsSet);
          if (operand != null) {
            operandStack.add(operand);
            operatorStack.add(Token.parser(TokenTypes.mul, "*"));
          }
        } else {
          operandStack.add(brackets);
        }
      } else {
        operandStack.add(parseOperand(tokenEnumerator, constantsSet));
      }
      // If we find a left parenthesis after the operand, consider this a multiplication!
      brackets = tryParseBrackets(tokenEnumerator, constantsSet);
      if (brackets != null) {
        if (brackets.symbol == Symbols.tuple && brackets.children.length == 1) {
          operandStack.add(brackets.children[0]);
          operatorStack.add(Token.parser(TokenTypes.mul, "*"));
          popOperatorStack(tokenEnumerator, operandStack, operatorStack);
        } else {
          operandStack.add(brackets);
        }
      }

      if (tryConsumeOperator(tokenEnumerator)) {
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

  static (ParseTree?, String?) tryParseOperand(
    LookaheadIterator<Token> tokenEnumerator,
    ConstantsSet constantsSet, [
    bool allowSign = true,
  ]) {
    if (!tokenEnumerator.hasNext) {
      return (null, 'End of token stream when expecting operand.');
    }

    if (tryConsumeSymbol(tokenEnumerator, Symbols.nullLiteral)) {
      return (ParseTree(Symbols.nullLiteral, []), null);
    }

    // If we find a plus or minus sign here, consider that a sign for the operand, then we recurse
    if (tryConsumeSymbol(tokenEnumerator, Symbols.add)) {
      return (
        ParseTree.withChildren(Symbols.unaryPlus, [
          parseOperand(tokenEnumerator, constantsSet, false),
        ]),
        null,
      );
    }

    if (tryConsumeSymbol(tokenEnumerator, Symbols.sub)) {
      return (
        ParseTree.withChildren(Symbols.unaryMinus, [
          parseOperand(tokenEnumerator, constantsSet, false),
        ]),
        null,
      );
    }

    if (tryConsumeSymbol(tokenEnumerator, Symbols.not)) {
      return (
        ParseTree.withChildren(Symbols.not, [
          parseOperand(tokenEnumerator, constantsSet),
        ]),
        null,
      );
    }

    if (tryConsumeTokenType(tokenEnumerator, TokenTypes.identifier)) {
      String identifierName = tokenEnumerator.current.lexeme;
      var brackets = tryParseBrackets(tokenEnumerator, constantsSet);
      List<ParseTree> children = [];
      if (brackets != null) {
        children.add(brackets);
      }

      return (
        ParseTree(
          Symbols.identifier,
          children,
          constantsSet.identifiers.include(identifierName.toUpperCase()),
        ),
        null,
      );
    }

    var literalType = tokenEnumerator.peek().literalType;
    if (literalType != LiteralTypes.none) {
      tokenEnumerator.next();
    }
    switch (literalType) {
      case LiteralTypes.integerLiteral:
        return (
          ParseTree.withQualifier(
            Symbols.integerLiteral,
            constantsSet.includeConstant(
              int.parse(tokenEnumerator.current.lexeme),
            ),
          ),
          null,
        );
      case LiteralTypes.floatLiteral:
        return (
          ParseTree.withQualifier(
            Symbols.floatLiteral,
            constantsSet.includeConstant(
              double.parse(tokenEnumerator.current.lexeme),
            ),
          ),
          null,
        );
      case LiteralTypes.doubleQuotedStringLiteral:
      case LiteralTypes.singleQuotedStringLiteral:
        return (
          ParseTree.withQualifier(
            Symbols.stringLiteral,
            constantsSet.includeConstant(
              StringEscaper.unescape(tokenEnumerator.current.lexeme),
            ),
          ),
          null,
        );
      case LiteralTypes.doubleQuotedRawStringLiteral:
      case LiteralTypes.singleQuotedRawStringLiteral:
        return (
          ParseTree.withQualifier(
            Symbols.stringLiteral,
            constantsSet.includeConstant(
              tokenEnumerator.current.lexeme.substring(
                2,
                tokenEnumerator.current.lexeme.length - 1,
              ),
            ),
          ),
          null,
        );
      default:
    }

    String currentLexeme = tokenEnumerator.peek().lexeme;

    return (null, 'Unexpected token "$currentLexeme" when expecting operand.');
  }

  static ParseTree parseOperand(
    LookaheadIterator<Token> tokenEnumerator,
    ConstantsSet constantsSet, [
    bool allowSign = true,
  ]) {
    var (parseTree, error) = tryParseOperand(
      tokenEnumerator,
      constantsSet,
      allowSign,
    );
    if (parseTree == null && error != null) {
      throw ParseException(error);
    }
    return parseTree!;
  }

  static ParseTree? tryParseBrackets(
    LookaheadIterator<Token> tokenEnumerator,
    ConstantsSet constantsSet,
  ) {
    if (!tokenEnumerator.hasNext || !tokenEnumerator.peek().isLeftBracket) {
      return null;
    }

    // Consume the left bracket
    var leftBracket = tokenEnumerator.next();
    var rightBracketType = leftBracket.correspondingRightBracket!;

    List<ParseTree> arguments = [];
    var result = ParseTree(leftBracket.bracketSymbol!, arguments);

    // Proceed to next token
    if (tryConsumeTokenType(tokenEnumerator, rightBracketType)) {
      // Empty argument list
      return result;
    }

    for (;;) {
      arguments.add(parse(tokenEnumerator, constantsSet));

      if (!tokenEnumerator.hasNext) {
        throw ParseException(
          "End of stream when expecting ${Token.tokenType2String(TokenTypes.comma)} or ${Token.tokenType2String(rightBracketType)}",
        );
      }

      tokenEnumerator.next();

      if (tokenEnumerator.current.tokenType == rightBracketType) {
        break;
      }

      if (tokenEnumerator.current.tokenType != TokenTypes.comma) {
        var n = arguments.length;
        throw ParseException(
          "Expected ${Token.tokenType2String(TokenTypes.comma)} or ${Token.tokenType2String(rightBracketType)} following $n:th member",
        );
      }
    }
    return result;
  }

  static bool tryConsumeOperator(LookaheadIterator<Token> tokenEnumerator) {
    if (tokenEnumerator.hasNext && tokenEnumerator.peek().isOperator()) {
      tokenEnumerator.next();
      return true;
    }
    return false;
  }

  static bool tryConsumeTokenType(
    LookaheadIterator<Token> tokenEnumerator,
    TokenTypes expectedTokenType,
  ) {
    if (!tokenEnumerator.hasNext) {
      return false;
    }
    if (tokenEnumerator.peek().tokenType == expectedTokenType) {
      tokenEnumerator.next();
      return true;
    }
    return false;
  }

  static bool tryConsumeSymbol(
    LookaheadIterator<Token> tokenEnumerator,
    Symbols expectedSymbol,
  ) {
    if (!tokenEnumerator.hasNext) {
      return false;
    }
    if (tokenEnumerator.peek().symbol == expectedSymbol) {
      tokenEnumerator.next();
      return true;
    }
    return false;
  }
}
