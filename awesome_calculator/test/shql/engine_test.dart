import 'package:awesome_calculator/shql/engine/engine.dart';
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
    expect(10, constantsSet.constants.constants[p.children[0].qualifier!]);
  });

  test('Calculate addition', () {
    expect(12, Engine.calculate('10+2'));
  });
  test('Calculate addition and multiplication', () {
    expect(492, Engine.calculate('10+13*37+1'));
  });

  test('Calculate implicit constant multiplication with parenthesis', () {
    expect(84, Engine.calculate('ANSWER(2)'));
  });

  test('Calculate implicit multiplication with parenthesis', () {
    expect(6, Engine.calculate('2(3)'));
  });

  test('Calculate addition and multiplication with parenthesis', () {
    expect(504, Engine.calculate('10+13*(37+1)'));
  });

  test('Calculate addition and implicit multiplication with parenthesis', () {
    expect(504, Engine.calculate('10+13(37+1)'));
  });

  test('Calculate addition, multiplication and subtraction', () {
    expect(490, Engine.calculate('10+13*37-1'));
  });

    test('Calculate addition, implicit multiplication and subtraction', () {
    expect(490, Engine.calculate('10+13(37)-1'));
  });

  test('Calculate addition, multiplication, subtraction and division', () {
    expect(249.5, Engine.calculate('10+13*37/2-1'));
  });

    test('Calculate addition, multiplication, subtraction and division', () {
    expect(249.5, Engine.calculate('10+13*37/2-1'));
  });

  test('Calculate addition, implicit multiplication, subtraction and division', () {
    expect(249.5, Engine.calculate('10+13(37)/2-1'));
  });

  test('Calculate modulus', () {
    expect(1, Engine.calculate('9%2'));
  });

  test('Calculate equality true', () {
    expect(1, Engine.calculate('5*2 = 2+8'));
  });

  test('Calculate equality false', () {
    expect(0, Engine.calculate('5*2 = 1+8'));
  });

  test('Calculate not equal true', () {
    expect(1, Engine.calculate('5*2 <> 1+8'));
  });

  test('Calculate not equal true with exclamation equals', () {
    expect(1, Engine.calculate('5*2 != 1+8'));
  });

  test('Evaluate match true', () {
    expect(1, Engine.calculate('"Super Man" ~  r"Super\\s*Man"'));
    expect(1, Engine.calculate('"Superman" ~  r"Super\\s*Man"'));
    expect(1, Engine.calculate('"Batman" ~  "batman"'));
  });

  test('Evaluate match false', () {
    expect(0, Engine.calculate('"Bat Man" ~  r"Super\\s*Man"'));
    expect(0, Engine.calculate('"Batman" ~  r"Super\\s*Man"'));
  });

  test('Evaluate mismatch true', () {
    expect(1, Engine.calculate('"Bat Man" !~  r"Super\\s*Man"'));
    expect(1, Engine.calculate('"Batman" !~  r"Super\\s*Man"'));

  });

  test('Evaluate mismatch false', () {
    expect(0, Engine.calculate('"Super Man" !~  r"Super\\s*Man"'));
    expect(0, Engine.calculate('"Superman" !~  r"Super\\s*Man"'));
  });

  test('Evaluate in list true', () {
    expect(1, Engine.calculate('"Super Man" in ["Super Man", "Batman"]'));
    expect(1, Engine.calculate('"Super Man" finns_i ["Super Man", "Batman"]'));
    expect(1, Engine.calculate('"Batman" in  ["Super Man", "Batman"]'));
    expect(1, Engine.calculate('"Batman" finns_i  ["Super Man", "Batman"]'));
  });

  test('Evaluate lower case in list true', () {
    expect(1, Engine.calculate('lowercase("Robin") in  ["batman", "robin"]'));
    expect(1, Engine.calculate('lowercase("Batman") in  ["batman", "robin"]'));
  });

  test('Evaluate in list false', () {
    expect(0, Engine.calculate('"Robin" in  ["Super Man", "Batman"]'));
    expect(0, Engine.calculate('"Superman" in ["Super Man", "Batman"]'));
  });

  test('Evaluate lower case in list false', () {
    expect(0, Engine.calculate('lowercase("robin") in  ["super man", "batman"]'));
    expect(0, Engine.calculate('lowercase("robin") finns_i  ["super man", "batman"]'));
    expect(0, Engine.calculate('lowercase("superman") in  ["super man", "batman"]'));
    expect(0, Engine.calculate('lowercase("superman") finns_i  ["super man", "batman"]'));
  });

  test('Calculate not equal false', () {
    expect(0, Engine.calculate('5*2 <> 2+8'));
  });

  test('Calculate not equal false with exclamation equals', () {
    expect(0, Engine.calculate('5*2 != 2+8'));
  });

  test('Calculate less than false', () {
    expect(0, Engine.calculate('10<1'));
  });

  test('Calculate less than true', () {
    expect(1, Engine.calculate('1<10'));
  });

  test('Calculate less than or equal false', () {
    expect(0, Engine.calculate('10<=1'));
  });

  test('Calculate less than or equal true', () {
    expect(1, Engine.calculate('1<=10'));
  });

  test('Calculate greater than false', () {
    expect(0, Engine.calculate('1>10'));
  });

  test('Calculate greater than true', () {
    expect(1, Engine.calculate('10>1'));
  });

  test('Calculate greater than or equal false', () {
    expect(0, Engine.calculate('1>=10'));
  });

  test('Calculate greater than or equal true', () {
    expect(1, Engine.calculate('10>=1'));
  });

  test('Calculate some boolean algebra and true', () {
    expect(1, Engine.calculate('1<10 AND 2<9'));
    expect(1, Engine.calculate('1<10 OCH 2<9'));
  });

  test('Calculate some boolean algebra and false', () {
    expect(0, Engine.calculate('1>10 AND 2<9'));
    expect(0, Engine.calculate('1>10 OCH 2<9'));
  });

  test('Calculate some boolean algebra or true', () {
    expect(1, Engine.calculate('1>10 OR 2<9'));
    expect(1, Engine.calculate('1>10 ELLER 2<9'));
  });

  test('Calculate some boolean algebra xor true', () {
    expect(1, Engine.calculate('1>10 XOR 2<9'));
    expect(1, Engine.calculate('1>10 ANTINGEN_ELLER 2<9'));
  });

  test('calculate_some_bool_algebra_xor_false', () {
    expect(0, Engine.calculate('10>1 XOR 2<9'));
    expect(0, Engine.calculate('10>1 ANTINGEN_ELLER 2<9'));
  });

  test('calculate_negation', () {
    expect(0, Engine.calculate('NOT 11'));
    expect(0, Engine.calculate('INTE 11'));
  });

  test('calculate_negation with exclamation', () {
    expect(0, Engine.calculate('!11'));
  });

  test('Calculate unary minus', () {
    expect(6, Engine.calculate('-5+11'));
  });

  test('Calculate unary plus', () {
    expect(16, Engine.calculate('+5+11'));
  });

  test('Calculate with constants', () {
    expect(3.1415926535897932 * 2, Engine.calculate('PI * 2'));
  });

  test('Calculate with lowercase constants', () {
    expect(3.1415926535897932 * 2, Engine.calculate('pi * 2'));
  });

  test('Calculate with functions', () {
    expect(4, Engine.calculate('POW(2,2)'));
  });

  test('Calculate with two functions', () {
    expect(6, Engine.calculate('POW(2,2)+SQRT(4)'));
  });

  test('Calculate nested function call', () {
    expect(2, Engine.calculate('SQRT(POW(2,2))'));
  });

  test('Calculate nested function call with expression', () {
    expect(3.7416573867739413, Engine.calculate('SQRT(POW(2,2)+10)'));
  });
}
