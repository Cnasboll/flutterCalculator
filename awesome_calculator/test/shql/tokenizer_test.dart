import 'package:awesome_calculator/shql/tokenizer/token.dart';
import 'package:awesome_calculator/shql/tokenizer/tokenizer.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('Tokenize addition', () {
    var v = Tokenizer.tokenize('10+2').toList();

    expect(3, v.length);
    expect(TokenTypes.integerLiteral, v[0].tokenType);
    expect(Symbols.none, v[0].symbol);
    expect(TokenTypes.add, v[1].tokenType);
    expect(Symbols.add, v[1].symbol);
    expect(TokenTypes.integerLiteral, v[2].tokenType);
    expect(Symbols.none, v[2].symbol);
  });

  test('Tokenize modulus', () {
    var v = Tokenizer.tokenize('9%2').toList();

    expect(3, v.length);
    expect(TokenTypes.integerLiteral, v[0].tokenType);
    expect(Symbols.none, v[0].symbol);
    expect(TokenTypes.mod, v[1].tokenType);
    expect(Symbols.mod, v[1].symbol);
    expect(TokenTypes.integerLiteral, v[2].tokenType);
    expect(Symbols.none, v[2].symbol);
  });

  test('Tokenize minimal double quoted string', () {
    var v = Tokenizer.tokenize('"h"').toList();

    expect(1, v.length);
    expect(TokenTypes.doubleQuotedStringLiteral, v[0].tokenType);
    expect(v[0].lexeme, '"h"');
    expect(Symbols.none, v[0].symbol);
  });

  test('Tokenize minimal single quoted string', () {
    var v = Tokenizer.tokenize("'h'").toList();

    expect(1, v.length);
    expect(TokenTypes.singleQuotedStringLiteral, v[0].tokenType);
    expect(v[0].lexeme, "'h'");
    expect(Symbols.none, v[0].symbol);
  });

  test('Tokenize double quoted strings', () {
    var v = Tokenizer.tokenize('"hello world" "good bye"').toList();

    expect(2, v.length);
    expect(TokenTypes.doubleQuotedStringLiteral, v[0].tokenType);
    expect(v[0].lexeme, '"hello world"');
    expect(Symbols.none, v[0].symbol);
    expect(TokenTypes.doubleQuotedStringLiteral, v[1].tokenType);
    expect(v[1].lexeme, '"good bye"');
    expect(Symbols.none, v[1].symbol);
  });

  test('Tokenize single quoted strings', () {
    var v = Tokenizer.tokenize("'hello world' 'good bye'").toList();

    expect(2, v.length);
    expect(TokenTypes.singleQuotedStringLiteral, v[0].tokenType);
    expect(v[0].lexeme, "'hello world'");
    expect(Symbols.none, v[0].symbol);
    expect(TokenTypes.singleQuotedStringLiteral, v[1].tokenType);
    expect(v[1].lexeme, "'good bye'");
    expect(Symbols.none, v[1].symbol);
  });

  test('Tokenize escaped double quoted string', () {
    var v = Tokenizer.tokenize('''"5'11\\""''').toList();

    expect(1, v.length);
    expect(TokenTypes.doubleQuotedStringLiteral, v[0].tokenType);
    expect(v[0].lexeme, '''"5'11\\""''');
    expect(Symbols.none, v[0].symbol);
  });

  test('Tokenize raw double quoted string', () {
    var v = Tokenizer.tokenize('r"hello\\s+world"').toList();

    expect(1, v.length);
    expect(TokenTypes.doubleQuotedRawStringLiteral, v[0].tokenType);
    expect(v[0].lexeme, 'r"hello\\s+world"');
    expect(Symbols.none, v[0].symbol);
  });

  test('Tokenize escaped single quoted string', () {
    var v = Tokenizer.tokenize("""'5\\'11"'""").toList();

    expect(1, v.length);
    expect(TokenTypes.singleQuotedStringLiteral, v[0].tokenType);
    expect(v[0].lexeme, """'5\\'11"'""");
    expect(Symbols.none, v[0].symbol);
  });

  test('Tokenize raw single quoted string', () {
    var v = Tokenizer.tokenize("r'hello\\s+world'").toList();

    expect(1, v.length);
    expect(TokenTypes.singleQuotedRawStringLiteral, v[0].tokenType);
    expect(v[0].lexeme, "r'hello\\s+world'");
    expect(Symbols.none, v[0].symbol);
  });

  test('Tokenize spaced identifiers', () {
    var v = Tokenizer.tokenize('hello world').toList();

    expect(2, v.length);
    expect(TokenTypes.identifier, v[0].tokenType);
    expect(Symbols.none, v[0].symbol);
    expect(TokenTypes.identifier, v[1].tokenType);
    expect(Symbols.none, v[1].symbol);
  });

  test('Tokenize keywords', () {
    var v = Tokenizer.tokenize('NOT INTE XOR ANTINGEN_ELLER AND OCH OR ELLER IN FINNS_I').toList();

    expect(10, v.length);

    expect(TokenTypes.identifier, v[0].tokenType);
    expect(Keywords.notKeyword, v[0].keyword);
    expect(Symbols.not, v[0].symbol);

  expect(TokenTypes.identifier, v[1].tokenType);
    expect(Keywords.notKeyword, v[1].keyword);
    expect(Symbols.not, v[1].symbol);

    expect(TokenTypes.identifier, v[2].tokenType);
    expect(Keywords.xorKeyword, v[2].keyword);
    expect(Symbols.xor, v[2].symbol);

    expect(TokenTypes.identifier, v[3].tokenType);
    expect(Keywords.xorKeyword, v[3].keyword);
    expect(Symbols.xor, v[3].symbol);

    expect(TokenTypes.identifier, v[4].tokenType);
    expect(Keywords.andKeyword, v[4].keyword);
    expect(Symbols.and, v[4].symbol);

    expect(TokenTypes.identifier, v[5].tokenType);
    expect(Keywords.andKeyword, v[5].keyword);
    expect(Symbols.and, v[5].symbol);

    expect(TokenTypes.identifier, v[6].tokenType);
    expect(Keywords.orKeyword, v[6].keyword);
    expect(Symbols.or, v[6].symbol);

    expect(TokenTypes.identifier, v[7].tokenType);
    expect(Keywords.orKeyword, v[7].keyword);
    expect(Symbols.or, v[7].symbol);

    expect(TokenTypes.identifier, v[8].tokenType);
    expect(Keywords.inKeyword, v[8].keyword);
    expect(Symbols.inOp, v[8].symbol);

    expect(TokenTypes.identifier, v[9].tokenType);
    expect(Keywords.inKeyword, v[9].keyword);
    expect(Symbols.inOp, v[9].symbol);

  });

  test('Tokenize lowercase keywords', () {
    var v = Tokenizer.tokenize('not xor and or in').toList();

    expect(5, v.length);
    expect(TokenTypes.identifier, v[0].tokenType);
    expect(Keywords.notKeyword, v[0].keyword);
    expect(Symbols.not, v[0].symbol);
    expect(TokenTypes.identifier, v[1].tokenType);
    expect(Keywords.xorKeyword, v[1].keyword);
    expect(Symbols.xor, v[1].symbol);
    expect(TokenTypes.identifier, v[2].tokenType);
    expect(Keywords.andKeyword, v[2].keyword);
    expect(Symbols.and, v[2].symbol);
    expect(TokenTypes.identifier, v[3].tokenType);
    expect(Keywords.orKeyword, v[3].keyword);
    expect(Symbols.or, v[3].symbol);
    expect(TokenTypes.identifier, v[4].tokenType);
    expect(Keywords.inKeyword, v[4].keyword);
    expect(Symbols.inOp, v[4].symbol);
  });

  test('Tokenize various characters', () {
    var v = Tokenizer.tokenize(', . [ ] ( ) !').toList();

    expect(7, v.length);
    expect(TokenTypes.comma, v[0].tokenType);
    expect(TokenTypes.dot, v[1].tokenType);
    expect(Symbols.memberAccess, v[1].symbol);
    expect(TokenTypes.lBrack, v[2].tokenType);
    expect(TokenTypes.rBrack, v[3].tokenType);
    expect(TokenTypes.lPar, v[4].tokenType);
    expect(TokenTypes.rPar, v[5].tokenType);
    expect(TokenTypes.not, v[6].tokenType);
    expect(Symbols.not, v[6].symbol);
  });
}
