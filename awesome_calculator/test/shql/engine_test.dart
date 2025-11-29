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
    expect(p.symbol, Symbols.add);
    expect(p.children[0].symbol, Symbols.integerLiteral);
    expect(constantsSet.constants.constants[p.children[0].qualifier!], 10);
    expect(p.children[1].symbol, Symbols.integerLiteral);
    expect(constantsSet.constants.constants[p.children[0].qualifier!], 10);
  });

  test('Calculate addition', () {
    expect(Engine.calculate('10+2'), 12);
  });
  test('Calculate addition and multiplication', () {
    expect(Engine.calculate('10+13*37+1'), 492);
  });

  test('Calculate implicit constant multiplication with parenthesis', () {
    expect(Engine.calculate('ANSWER(2)'), 84);
  });

  test('Calculate implicit multiplication with parenthesis', () {
    expect(Engine.calculate('2(3)'), 6);
  });

  test('Calculate addition and multiplication with parenthesis', () {
    expect(Engine.calculate('10+13*(37+1)'), 504);
  });

  test('Calculate addition and implicit multiplication with parenthesis', () {
    expect(Engine.calculate('10+13(37+1)'), 504);
  });

  test('Calculate addition, multiplication and subtraction', () {
    expect(Engine.calculate('10+13*37-1'), 490);
  });

  test('Calculate addition, implicit multiplication and subtraction', () {
    expect(Engine.calculate('10+13(37)-1'), 490);
  });

  test('Calculate addition, multiplication, subtraction and division', () {
    expect(Engine.calculate('10+13*37/2-1'), 249.5);
  });

  test('Calculate addition, multiplication, subtraction and division', () {
    expect(Engine.calculate('10+13*37/2-1'), 249.5);
  });

  test(
    'Calculate addition, implicit multiplication, subtraction and division',
    () {
      expect(Engine.calculate('10+13(37)/2-1'), 249.5);
    },
  );

  test('Calculate modulus', () {
    expect(Engine.calculate('9%2'), 1);
  });

  test('Calculate equality true', () {
    expect(Engine.calculate('5*2 = 2+8'), true);
  });

  test('Calculate equality false', () {
    expect(Engine.calculate('5*2 = 1+8'), false);
  });

  test('Calculate not equal true', () {
    expect(Engine.calculate('5*2 <> 1+8'), true);
  });

  test('Calculate not equal true with exclamation equals', () {
    expect(Engine.calculate('5*2 != 1+8'), true);
  });

  test('Evaluate match true', () {
    expect(Engine.calculate('"Super Man" ~  r"Super\\s*Man"'), true);
    expect(Engine.calculate('"Superman" ~  r"Super\\s*Man"'), true);
    expect(Engine.calculate('"Batman" ~  "batman"'), true);
  });

  test('Evaluate match false', () {
    expect(Engine.calculate('"Bat Man" ~  r"Super\\s*Man"'), false);
    expect(Engine.calculate('"Batman" ~  r"Super\\s*Man"'), false);
  });

  test('Evaluate mismatch true', () {
    expect(Engine.calculate('"Bat Man" !~  r"Super\\s*Man"'), true);
    expect(Engine.calculate('"Batman" !~  r"Super\\s*Man"'), true);
  });

  test('Evaluate mismatch false', () {
    expect(Engine.calculate('"Super Man" !~  r"Super\\s*Man"'), false);
    expect(Engine.calculate('"Superman" !~  r"Super\\s*Man"'), false);
  });

  test('Evaluate in list true', () {
    expect(Engine.calculate('"Super Man" in ["Super Man", "Batman"]'), true);
    expect(
      Engine.calculate('"Super Man" finns_i ["Super Man", "Batman"]'),
      true,
    );
    expect(Engine.calculate('"Batman" in  ["Super Man", "Batman"]'), true);
    expect(Engine.calculate('"Batman" finns_i  ["Super Man", "Batman"]'), true);
  });

  test('Evaluate lower case in list true', () {
    expect(
      Engine.calculate('lowercase("Robin") in  ["batman", "robin"]'),
      true,
    );
    expect(
      Engine.calculate('lowercase("Batman") in  ["batman", "robin"]'),
      true,
    );
  });

  test('Evaluate in list false', () {
    expect(Engine.calculate('"Robin" in  ["Super Man", "Batman"]'), false);
    expect(Engine.calculate('"Superman" in ["Super Man", "Batman"]'), false);
  });

  test('Evaluate lower case in list false', () {
    expect(
      Engine.calculate('lowercase("robin") in  ["super man", "batman"]'),
      false,
    );
    expect(
      Engine.calculate('lowercase("robin") finns_i  ["super man", "batman"]'),
      false,
    );
    expect(
      Engine.calculate('lowercase("superman") in  ["super man", "batman"]'),
      false,
    );
    expect(
      Engine.calculate(
        'lowercase("superman") finns_i  ["super man", "batman"]',
      ),
      false,
    );
  });

  test('Calculate not equal false', () {
    expect(Engine.calculate('5*2 <> 2+8'), false);
  });

  test('Calculate not equal false with exclamation equals', () {
    expect(Engine.calculate('5*2 != 2+8'), false);
  });

  test('Calculate less than false', () {
    expect(Engine.calculate('10<1'), false);
  });

  test('Calculate less than true', () {
    expect(Engine.calculate('1<10'), true);
  });

  test('Calculate less than or equal false', () {
    expect(Engine.calculate('10<=1'), false);
  });

  test('Calculate less than or equal true', () {
    expect(Engine.calculate('1<=10'), true);
  });

  test('Calculate greater than false', () {
    expect(Engine.calculate('1>10'), false);
  });

  test('Calculate greater than true', () {
    expect(Engine.calculate('10>1'), true);
  });

  test('Calculate greater than or equal false', () {
    expect(Engine.calculate('1>=10'), false);
  });

  test('Calculate greater than or equal true', () {
    expect(Engine.calculate('10>=1'), true);
  });

  test('Calculate some boolean algebra and true', () {
    expect(Engine.calculate('1<10 AND 2<9'), true);
    expect(Engine.calculate('1<10 OCH 2<9'), true);
  });

  test('Calculate some boolean algebra and false', () {
    expect(Engine.calculate('1>10 AND 2<9'), false);
    expect(Engine.calculate('1>10 OCH 2<9'), false);
  });

  test('Calculate some boolean algebra or true', () {
    expect(Engine.calculate('1>10 OR 2<9'), true);
    expect(Engine.calculate('1>10 ELLER 2<9'), true);
  });

  test('Calculate some boolean algebra xor true', () {
    expect(Engine.calculate('1>10 XOR 2<9'), true);
    expect(Engine.calculate('1>10 ANTINGEN_ELLER 2<9'), true);
  });

  test('calculate_some_bool_algebra_xor_false', () {
    expect(Engine.calculate('10>1 XOR 2<9'), false);
    expect(Engine.calculate('10>1 ANTINGEN_ELLER 2<9'), false);
  });

  test('calculate_negation', () {
    expect(Engine.calculate('NOT 11'), false);
    expect(Engine.calculate('INTE 11'), false);
  });

  test('calculate_negation with exclamation', () {
    expect(Engine.calculate('!11'), false);
  });

  test('Calculate unary minus', () {
    expect(Engine.calculate('-5+11'), 6);
  });

  test('Calculate unary plus', () {
    expect(Engine.calculate('+5+11'), 16);
  });

  test('Calculate with constants', () {
    expect(Engine.calculate('PI * 2'), 3.1415926535897932 * 2);
  });

  test('Calculate with lowercase constants', () {
    expect(Engine.calculate('pi * 2'), 3.1415926535897932 * 2);
  });

  test('Calculate with functions', () {
    expect(Engine.calculate('POW(2,2)'), 4);
  });

  test('Calculate with two functions', () {
    expect(Engine.calculate('POW(2,2)+SQRT(4)'), 6);
  });

  test('Calculate nested function call', () {
    expect(Engine.calculate('SQRT(POW(2,2))'), 2);
  });

  test('Calculate nested function call with expression', () {
    expect(Engine.calculate('SQRT(POW(2,2)+10)'), 3.7416573867739413);
  });

  test('Calculate two expressions', () {
    expect(Engine.calculate('10;11'), 11);
  });
  test('Calculate two expressions with final semicolon', () {
    expect(Engine.calculate('10;11;'), 11);
  });

  test('Test assignment', () {
    expect(Engine.calculate('i:=42'), 42);
  });

  test('Test increment', () {
    expect(Engine.calculate('i:=41;i:=i+1'), 42);
  });
}
