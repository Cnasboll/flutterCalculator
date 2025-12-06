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
    var p = Parser.parseExpression(v.lookahead(), constantsSet);
    expect(p.symbol, Symbols.add);
    expect(p.children[0].symbol, Symbols.integerLiteral);
    expect(constantsSet.getConstantByIndex(p.children[0].qualifier!), 10);
    expect(p.children[1].symbol, Symbols.integerLiteral);
    expect(constantsSet.getConstantByIndex(p.children[1].qualifier!), 2);
  });

  test('Parse addition and multiplication', () {
    var v = Tokenizer.tokenize('10+13*37+1').toList();
    var constantsSet = ConstantsSet();
    var p = Parser.parseExpression(v.lookahead(), constantsSet);
    expect(p.symbol, Symbols.add);
    expect(p.children[0].symbol, Symbols.add);
    expect(p.children[0].children[0].symbol, Symbols.integerLiteral);
    expect(
      constantsSet.getConstantByIndex(p.children[0].children[0].qualifier!),
      10,
    );
    expect(p.children[0].children[1].symbol, Symbols.mul);
    expect(
      p.children[0].children[1].children[0].symbol,
      Symbols.integerLiteral,
    );
    expect(
      constantsSet.getConstantByIndex(
        p.children[0].children[1].children[0].qualifier!,
      ),
      13,
    );
    expect(
      p.children[0].children[1].children[1].symbol,
      Symbols.integerLiteral,
    );
    expect(
      constantsSet.getConstantByIndex(
        p.children[0].children[1].children[1].qualifier!,
      ),
      37,
    );
    expect(p.children[1].symbol, Symbols.integerLiteral);
    expect(constantsSet.getConstantByIndex(p.children[1].qualifier!), 1);
  });

  test('Parse addition and multiplication with parenthesis', () {
    var v = Tokenizer.tokenize('10+13*(37+1)').toList();
    var constantsSet = ConstantsSet();
    var p = Parser.parseExpression(v.lookahead(), constantsSet);
    expect(p.symbol, Symbols.add);
    expect(p.children[0].symbol, Symbols.integerLiteral);
    expect(constantsSet.getConstantByIndex(p.children[0].qualifier!), 10);
    expect(p.children[1].symbol, Symbols.mul);
    expect(p.children[1].children[0].symbol, Symbols.integerLiteral);
    expect(
      constantsSet.getConstantByIndex(p.children[1].children[0].qualifier!),
      13,
    );
    expect(p.children[1].children[1].symbol, Symbols.add);
    expect(
      p.children[1].children[1].children[0].symbol,
      Symbols.integerLiteral,
    );
    expect(
      constantsSet.getConstantByIndex(
        p.children[1].children[1].children[0].qualifier!,
      ),
      37,
    );
    expect(
      p.children[1].children[1].children[1].symbol,
      Symbols.integerLiteral,
    );
    expect(
      constantsSet.getConstantByIndex(
        p.children[1].children[1].children[1].qualifier!,
      ),
      1,
    );
  });

  test('Parse addition, multiplication and subtraction', () {
    var v = Tokenizer.tokenize('10+13*37-1').toList();
    var constantsSet = ConstantsSet();
    var p = Parser.parseExpression(v.lookahead(), constantsSet);
    expect(p.symbol, Symbols.sub);
    expect(p.children[0].symbol, Symbols.add);
    expect(p.children[0].children[0].symbol, Symbols.integerLiteral);
    expect(
      constantsSet.getConstantByIndex(p.children[0].children[0].qualifier!),
      10,
    );
    expect(p.children[0].children[1].symbol, Symbols.mul);
    expect(
      p.children[0].children[1].children[0].symbol,
      Symbols.integerLiteral,
    );
    expect(
      constantsSet.getConstantByIndex(
        p.children[0].children[1].children[0].qualifier!,
      ),
      13,
    );
    expect(
      p.children[0].children[1].children[1].symbol,
      Symbols.integerLiteral,
    );
    expect(
      constantsSet.getConstantByIndex(
        p.children[0].children[1].children[1].qualifier!,
      ),
      37,
    );
    expect(p.children[1].symbol, Symbols.integerLiteral);
    expect(constantsSet.getConstantByIndex(p.children[1].qualifier!), 1);
  });

  test('Parse function call', () {
    var v = Tokenizer.tokenize('f()').toList();
    var constantsSet = ConstantsSet();
    var p = Parser.parseExpression(v.lookahead(), constantsSet);
    expect(p.symbol, Symbols.identifier);
    expect(p.children.length, 1);
    expect(p.children[0].symbol, Symbols.tuple);
    expect(p.children[0].children.isEmpty, true);
  });

  test('Parse function call followed by operator', () {
    var v = Tokenizer.tokenize('f()+1').toList();
    var constantsSet = ConstantsSet();
    var p = Parser.parseExpression(v.lookahead(), constantsSet);
    expect(p.symbol, Symbols.add);
    expect(p.children.length, 2);
  });

  test('Parse function call with 1 arg', () {
    var v = Tokenizer.tokenize('f(1)').toList();
    var constantsSet = ConstantsSet();
    var p = Parser.parseExpression(v.lookahead(), constantsSet);
    expect(p.symbol, Symbols.identifier);
    expect(p.children.length, 1);
  });

  test('Parse function call with 1 arg followed by operator', () {
    var v = Tokenizer.tokenize('f(1)+1').toList();
    var constantsSet = ConstantsSet();
    var p = Parser.parseExpression(v.lookahead(), constantsSet);
    expect(p.symbol, Symbols.add);
    expect(p.children.length, 2);
  });

  test(
    'Parse function call with 1 arg and operator with expression followed by operator',
    () {
      var v = Tokenizer.tokenize('f(1*2, 2)+1').toList();
      var constantsSet = ConstantsSet();
      var p = Parser.parseExpression(v.lookahead(), constantsSet);
      expect(p.symbol, Symbols.add);
      expect(p.children.length, 2);
    },
  );

  test('Parse empty list', () {
    var v = Tokenizer.tokenize('[]').toList();
    var constantsSet = ConstantsSet();
    var p = Parser.parseExpression(v.lookahead(), constantsSet);
    expect(p.symbol, Symbols.list);
    expect(p.children.isEmpty, true);
  });

  test('Parse empty list followed by operator', () {
    var v = Tokenizer.tokenize('[]+1').toList();
    var constantsSet = ConstantsSet();
    var p = Parser.parseExpression(v.lookahead(), constantsSet);
    expect(p.symbol, Symbols.add);
    expect(p.children.length, 2);
    var list = p.children[0];
    expect(list.symbol, Symbols.list);
    expect(list.children.isEmpty, true);
  });

  test('Parse list of one element ', () {
    var v = Tokenizer.tokenize('[1]').toList();
    var constantsSet = ConstantsSet();
    var p = Parser.parseExpression(v.lookahead(), constantsSet);
    expect(p.symbol, Symbols.list);
    expect(p.children.length, 1);
  });

  test('Parse list of one element followed by operator', () {
    var v = Tokenizer.tokenize('[1]+1').toList();
    var constantsSet = ConstantsSet();
    var p = Parser.parseExpression(v.lookahead(), constantsSet);
    expect(p.symbol, Symbols.add);
    expect(p.children.length, 2);
    var list = p.children[0];
    expect(list.symbol, Symbols.list);
    expect(list.children.length, 1);
  });

  test(
    'Parse list of two elements, one with operator, followed by operator',
    () {
      var v = Tokenizer.tokenize('[1*2, 2]+1').toList();
      var constantsSet = ConstantsSet();
      var p = Parser.parseExpression(v.lookahead(), constantsSet);
      expect(p.symbol, Symbols.add);
      expect(p.children.length, 2);
      var list = p.children[0];
      expect(list.symbol, Symbols.list);
      expect(list.children.length, 2);
    },
  );

  test('Parse list membership', () {
    var v = Tokenizer.tokenize('2 IN [1, 2]').toList();
    var constantsSet = ConstantsSet();
    var p = Parser.parseExpression(v.lookahead(), constantsSet);
    expect(p.symbol, Symbols.inOp);
    expect(p.children.length, 2);
    var list = p.children[1];
    expect(list.symbol, Symbols.list);
    expect(list.children.length, 2);
  });

  test('Parse list membership lowercase', () {
    var v = Tokenizer.tokenize('2 in [1, 2]').toList();
    var constantsSet = ConstantsSet();
    var p = Parser.parseExpression(v.lookahead(), constantsSet);
    expect(p.symbol, Symbols.inOp);
    expect(p.children.length, 2);
    var list = p.children[1];
    expect(list.symbol, Symbols.list);
    expect(list.children.length, 2);
  });
  test('Parse member access', () {
    var v = Tokenizer.tokenize('powerstats.strength').toList();
    var constantsSet = ConstantsSet();
    var p = Parser.parseExpression(v.lookahead(), constantsSet);
    expect(p.symbol, Symbols.memberAccess);
    expect(p.children.length, 2);
    var powerstats = p.children[0];
    expect(powerstats.symbol, Symbols.identifier);
    expect(
      powerstats.qualifier,
      constantsSet.identifiers.include('POWERSTATS'),
    );
    var strength = p.children[1];
    expect(strength.symbol, Symbols.identifier);
    expect(strength.qualifier, constantsSet.identifiers.include('STRENGTH'));
  });
}
