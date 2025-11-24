import 'package:awesome_calculator/shql/parser/constants_set.dart';
import 'package:awesome_calculator/shql/parser/lookahead_iterator.dart';
import 'package:awesome_calculator/shql/parser/parser.dart';
import 'package:awesome_calculator/shql/tokenizer/token.dart';
import 'package:awesome_calculator/shql/tokenizer/tokenizer.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
    test('Parse addition', () {
    var v = Tokenizer.tokenize('10+2').toList();
    var constantsSet = ConstantsSet();
    var p = Parser.parse(v.lookahead(), constantsSet);
    expect(Symbols.add, p.symbol);
    expect(Symbols.integerLiteral, p.children[0].symbol);
    expect(10, constantsSet.constants.constants[p.children[0].qualifier!]);
    expect(Symbols.integerLiteral, p.children[1].symbol);
    expect(2, constantsSet.constants.constants[p.children[1].qualifier!]);
  });

  test('Parse addition and multiplication', () {
    var v = Tokenizer.tokenize('10+13*37+1').toList();
    var constantsSet = ConstantsSet();
    var p = Parser.parse(v.lookahead(), constantsSet);
    expect(Symbols.add, p.symbol);
    expect(Symbols.add, p.children[0].symbol);
    expect(Symbols.integerLiteral, p.children[0].children[0].symbol);
    expect(
      10,
      constantsSet.constants.constants[p.children[0].children[0].qualifier!],
    );
    expect(Symbols.mul, p.children[0].children[1].symbol);
    expect(
      Symbols.integerLiteral,
      p.children[0].children[1].children[0].symbol,
    );
    expect(
      13,
      constantsSet.constants.constants[p
          .children[0]
          .children[1]
          .children[0]
          .qualifier!],
    );
    expect(
      Symbols.integerLiteral,
      p.children[0].children[1].children[1].symbol,
    );
    expect(
      37,
      constantsSet.constants.constants[p
          .children[0]
          .children[1]
          .children[1]
          .qualifier!],
    );
    expect(Symbols.integerLiteral, p.children[1].symbol);
    expect(1, constantsSet.constants.constants[p.children[1].qualifier!]);
  });

  test('Parse addition and multiplication with parenthesis', () {
    var v = Tokenizer.tokenize('10+13*(37+1)').toList();
    var constantsSet = ConstantsSet();
    var p = Parser.parse(v.lookahead(), constantsSet);
    expect(Symbols.add, p.symbol);
    expect(Symbols.integerLiteral, p.children[0].symbol);
    expect(10, constantsSet.constants.constants[p.children[0].qualifier!]);
    expect(Symbols.mul, p.children[1].symbol);
    expect(Symbols.integerLiteral, p.children[1].children[0].symbol);
    expect(
      13,
      constantsSet.constants.constants[p.children[1].children[0].qualifier!],
    );
    expect(Symbols.add, p.children[1].children[1].symbol);
    expect(
      Symbols.integerLiteral,
      p.children[1].children[1].children[0].symbol,
    );
    expect(
      37,
      constantsSet.constants.constants[p
          .children[1]
          .children[1]
          .children[0]
          .qualifier!],
    );
    expect(
      Symbols.integerLiteral,
      p.children[1].children[1].children[1].symbol,
    );
    expect(
      1,
      constantsSet.constants.constants[p
          .children[1]
          .children[1]
          .children[1]
          .qualifier!],
    );
  });

  test('Parse addition, multiplication and subtraction', () {
    var v = Tokenizer.tokenize('10+13*37-1').toList();
    var constantsSet = ConstantsSet();
    var p = Parser.parse(v.lookahead(), constantsSet);
    expect(Symbols.sub, p.symbol);
    expect(Symbols.add, p.children[0].symbol);
    expect(Symbols.integerLiteral, p.children[0].children[0].symbol);
    expect(
      10,
      constantsSet.constants.constants[p.children[0].children[0].qualifier!],
    );
    expect(Symbols.mul, p.children[0].children[1].symbol);
    expect(
      Symbols.integerLiteral,
      p.children[0].children[1].children[0].symbol,
    );
    expect(
      13,
      constantsSet.constants.constants[p
          .children[0]
          .children[1]
          .children[0]
          .qualifier!],
    );
    expect(
      Symbols.integerLiteral,
      p.children[0].children[1].children[1].symbol,
    );
    expect(
      37,
      constantsSet.constants.constants[p
          .children[0]
          .children[1]
          .children[1]
          .qualifier!],
    );
    expect(Symbols.integerLiteral, p.children[1].symbol);
    expect(1, constantsSet.constants.constants[p.children[1].qualifier!]);
  });

  test('Parse function call', () {
    var v = Tokenizer.tokenize('f()').toList();
    var constantsSet = ConstantsSet();
    var p = Parser.parse(v.lookahead(), constantsSet);
    expect(Symbols.identifier, p.symbol);
    expect(true, p.children.isEmpty);
  });

  test('Parse function call followed by operator', () {
    var v = Tokenizer.tokenize('f()+1').toList();
    var constantsSet = ConstantsSet();
    var p = Parser.parse(v.lookahead(), constantsSet);
    expect(Symbols.add, p.symbol);
    expect(2, p.children.length);
  });

  test('Parse function call with 1 arg', () {
    var v = Tokenizer.tokenize('f(1)').toList();
    var constantsSet = ConstantsSet();
    var p = Parser.parse(v.lookahead(), constantsSet);
    expect(Symbols.identifier, p.symbol);
    expect(1, p.children.length);
  });

  test('Parse function call with 1 arg followed by operator', () {
    var v = Tokenizer.tokenize('f(1)+1').toList();
    var constantsSet = ConstantsSet();
    var p = Parser.parse(v.lookahead(), constantsSet);
    expect(Symbols.add, p.symbol);
    expect(2, p.children.length);
  });

  test('Parse function call with 1 arg and operator with expression followed by operator', () {
    var v = Tokenizer.tokenize('f(1*2, 2)+1').toList();
    var constantsSet = ConstantsSet();
    var p = Parser.parse(v.lookahead(), constantsSet);
    expect(Symbols.add, p.symbol);
    expect(2, p.children.length);
  });

  test('Parse empty list', () {
    var v = Tokenizer.tokenize('[]').toList();
    var constantsSet = ConstantsSet();
    var p = Parser.parse(v.lookahead(), constantsSet);
    expect(Symbols.list, p.symbol);
    expect(true, p.children.isEmpty);
  });

  test('Parse empty list followed by operator', () {
    var v = Tokenizer.tokenize('[]+1').toList();
    var constantsSet = ConstantsSet();
    var p = Parser.parse(v.lookahead(), constantsSet);
    expect(Symbols.add, p.symbol);
    expect(2, p.children.length);
    var list = p.children[0];
    expect(Symbols.list, list.symbol);
    expect(true, list.children.isEmpty);
  });

  test('Parse list of one element ', () {
    var v = Tokenizer.tokenize('[1]').toList();
    var constantsSet = ConstantsSet();
    var p = Parser.parse(v.lookahead(), constantsSet);
    expect(Symbols.list, p.symbol);
    expect(1, p.children.length);
  });

  test('Parse list of one element followed by operator', () {
    var v = Tokenizer.tokenize('[1]+1').toList();
    var constantsSet = ConstantsSet();
    var p = Parser.parse(v.lookahead(), constantsSet);
    expect(Symbols.add, p.symbol);
    expect(2, p.children.length);
    var list = p.children[0];
    expect(Symbols.list, list.symbol);
    expect(1, list.children.length);
  });

  test('Parse list of two elements, one with operator, followed by operator', () {
    var v = Tokenizer.tokenize('[1*2, 2]+1').toList();
    var constantsSet = ConstantsSet();
    var p = Parser.parse(v.lookahead(), constantsSet);
    expect(Symbols.add, p.symbol);
    expect(2, p.children.length);
    var list = p.children[0];
    expect(Symbols.list, list.symbol);
    expect(2, list.children.length);
  });

  test('Parse list membership', () {
    var v = Tokenizer.tokenize('2 IN [1, 2]').toList();
    var constantsSet = ConstantsSet();
    var p = Parser.parse(v.lookahead(), constantsSet);
    expect(Symbols.inOp, p.symbol);
    expect(2, p.children.length);
    var list = p.children[1];
    expect(Symbols.list, list.symbol);
    expect(2, list.children.length);
  });

  test('Parse list membership lowercase', () {
    var v = Tokenizer.tokenize('2 in [1, 2]').toList();
    var constantsSet = ConstantsSet();
    var p = Parser.parse(v.lookahead(), constantsSet);
    expect(Symbols.inOp, p.symbol);
    expect(2, p.children.length);
    var list = p.children[1];
    expect(Symbols.list, list.symbol);
    expect(2, list.children.length);
  });
test('Parse member access', () {
    var v = Tokenizer.tokenize('powerstats.strength').toList();
    var constantsSet = ConstantsSet();
    var p = Parser.parse(v.lookahead(), constantsSet);
    expect(Symbols.memberAccess, p.symbol);
    expect(2, p.children.length);
    var powerstats = p.children[0];
    expect(Symbols.identifier, powerstats.symbol);
    expect(
      constantsSet.identifiers.include('POWERSTATS'),
      powerstats.qualifier,
    );
    var strength = p.children[1];
    expect(Symbols.identifier, strength.symbol);
    expect(constantsSet.identifiers.include('STRENGTH'), strength.qualifier);
  });

}
