import 'package:awesome_calculator/shql/engine/engine.dart';
import 'package:awesome_calculator/shql/execution/runtime.dart';
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
    expect(constantsSet.getConstantByIndex(p.children[0].qualifier!), 10);
    expect(p.children[1].symbol, Symbols.integerLiteral);
    expect(constantsSet.getConstantByIndex(p.children[1].qualifier!), 2);
  });

  test('Calculate addition', () async {
    expect(await Engine.execute('10+2'), 12);
  });
  test('Calculate addition and multiplication', () async {
    expect(await Engine.execute('10+13*37+1'), 492);
  });

  test('Calculate implicit constant multiplication with parenthesis', () async {
    expect(await Engine.execute('ANSWER(2)'), 84);
  });

  test(
    'Calculate implicit constant multiplication with parenthesis first',
    () async {
      expect(await Engine.execute('(2)ANSWER'), 84);
    },
  );

  test(
    'Calculate implicit constant multiplication with constant within parenthesis first',
    () async {
      expect(await Engine.execute('(ANSWER)2'), 84);
    },
  );

  test('Calculate implicit multiplication with parenthesis', () async {
    expect(await Engine.execute('2(3)'), 6);
  });

  test('Calculate addition and multiplication with parenthesis', () async {
    expect(await Engine.execute('10+13*(37+1)'), 504);
  });

  test(
    'Calculate addition and implicit multiplication with parenthesis',
    () async {
      expect(await Engine.execute('10+13(37+1)'), 504);
    },
  );

  test('Calculate addition, multiplication and subtraction', () async {
    expect(await Engine.execute('10+13*37-1'), 490);
  });

  test('Calculate addition, implicit multiplication and subtraction', () async {
    expect(await Engine.execute('10+13(37)-1'), 490);
  });

  test(
    'Calculate addition, multiplication, subtraction and division',
    () async {
      expect(await Engine.execute('10+13*37/2-1'), 249.5);
    },
  );

  test(
    'Calculate addition, multiplication, subtraction and division',
    () async {
      expect(await Engine.execute('10+13*37/2-1'), 249.5);
    },
  );

  test(
    'Calculate addition, implicit multiplication, subtraction and division',
    () async {
      expect(await Engine.execute('10+13(37)/2-1'), 249.5);
    },
  );

  test('Calculate modulus', () async {
    expect(await Engine.execute('9%2'), 1);
  });

  test('Calculate equality true', () async {
    expect(await Engine.execute('5*2 = 2+8'), true);
  });

  test('Calculate equality false', () async {
    expect(await Engine.execute('5*2 = 1+8'), false);
  });

  test('Calculate not equal true', () async {
    expect(await Engine.execute('5*2 <> 1+8'), true);
  });

  test('Calculate not equal true with exclamation equals', () async {
    expect(await Engine.execute('5*2 != 1+8'), true);
  });

  test('Evaluate match true', () async {
    expect(await Engine.execute('"Super Man" ~  r"Super\\s*Man"'), true);
    expect(await Engine.execute('"Superman" ~  r"Super\\s*Man"'), true);
    expect(await Engine.execute('"Batman" ~  "batman"'), true);
  });

  test('Evaluate match false', () async {
    expect(await Engine.execute('"Bat Man" ~  r"Super\\s*Man"'), false);
    expect(await Engine.execute('"Batman" ~  r"Super\\s*Man"'), false);
  });

  test('Evaluate mismatch true', () async {
    expect(await Engine.execute('"Bat Man" !~  r"Super\\s*Man"'), true);
    expect(await Engine.execute('"Batman" !~  r"Super\\s*Man"'), true);
  });

  test('Evaluate mismatch false', () async {
    expect(await Engine.execute('"Super Man" !~  r"Super\\s*Man"'), false);
    expect(await Engine.execute('"Superman" !~  r"Super\\s*Man"'), false);
  });

  test('Evaluate in list true', () async {
    expect(
      await Engine.execute('"Super Man" in ["Super Man", "Batman"]'),
      true,
    );
    expect(
      await Engine.execute('"Super Man" finns_i ["Super Man", "Batman"]'),
      true,
    );
    expect(await Engine.execute('"Batman" in  ["Super Man", "Batman"]'), true);
    expect(
      await Engine.execute('"Batman" finns_i  ["Super Man", "Batman"]'),
      true,
    );
  });

  test('Evaluate lower case in list true', () async {
    expect(
      await Engine.execute('lowercase("Robin") in  ["batman", "robin"]'),
      true,
    );
    expect(
      await Engine.execute('lowercase("Batman") in  ["batman", "robin"]'),
      true,
    );
  });

  test('Evaluate in list false', () async {
    expect(await Engine.execute('"Robin" in  ["Super Man", "Batman"]'), false);
    expect(
      await Engine.execute('"Superman" in ["Super Man", "Batman"]'),
      false,
    );
  });

  test('Evaluate lower case in list false', () async {
    expect(
      await Engine.execute('lowercase("robin") in  ["super man", "batman"]'),
      false,
    );
    expect(
      await Engine.execute(
        'lowercase("robin") finns_i  ["super man", "batman"]',
      ),
      false,
    );
    expect(
      await Engine.execute('lowercase("superman") in  ["super man", "batman"]'),
      false,
    );
    expect(
      await Engine.execute(
        'lowercase("superman") finns_i  ["super man", "batman"]',
      ),
      false,
    );
  });

  test('Calculate not equal false', () async {
    expect(await Engine.execute('5*2 <> 2+8'), false);
  });

  test('Calculate not equal false with exclamation equals', () async {
    expect(await Engine.execute('5*2 != 2+8'), false);
  });

  test('Calculate less than false', () async {
    expect(await Engine.execute('10<1'), false);
  });

  test('Calculate less than true', () async {
    expect(await Engine.execute('1<10'), true);
  });

  test('Calculate less than or equal false', () async {
    expect(await Engine.execute('10<=1'), false);
  });

  test('Calculate less than or equal true', () async {
    expect(await Engine.execute('1<=10'), true);
  });

  test('Calculate greater than false', () async {
    expect(await Engine.execute('1>10'), false);
  });

  test('Calculate greater than true', () async {
    expect(await Engine.execute('10>1'), true);
  });

  test('Calculate greater than or equal false', () async {
    expect(await Engine.execute('1>=10'), false);
  });

  test('Calculate greater than or equal true', () async {
    expect(await Engine.execute('10>=1'), true);
  });

  test('Calculate some boolean algebra and true', () async {
    expect(await Engine.execute('1<10 AND 2<9'), true);
    expect(await Engine.execute('1<10 OCH 2<9'), true);
  });

  test('Calculate some boolean algebra and false', () async {
    expect(await Engine.execute('1>10 AND 2<9'), false);
    expect(await Engine.execute('1>10 OCH 2<9'), false);
  });

  test('Calculate some boolean algebra or true', () async {
    expect(await Engine.execute('1>10 OR 2<9'), true);
    expect(await Engine.execute('1>10 ELLER 2<9'), true);
  });

  test('Calculate some boolean algebra xor true', () async {
    expect(await Engine.execute('1>10 XOR 2<9'), true);
    expect(await Engine.execute('1>10 ANTINGEN_ELLER 2<9'), true);
  });

  test('calculate_some_bool_algebra_xor_false', () async {
    expect(await Engine.execute('10>1 XOR 2<9'), false);
    expect(await Engine.execute('10>1 ANTINGEN_ELLER 2<9'), false);
  });

  test('calculate_negation', () async {
    expect(await Engine.execute('NOT 11'), false);
    expect(await Engine.execute('INTE 11'), false);
  });

  test('calculate_negation with exclamation', () async {
    expect(await Engine.execute('!11'), false);
  });

  test('Calculate unary minus', () async {
    expect(await Engine.execute('-5+11'), 6);
  });

  test('Calculate unary plus', () async {
    expect(await Engine.execute('+5+11'), 16);
  });

  test('Calculate with constants', () async {
    expect(await Engine.execute('PI * 2'), 3.1415926535897932 * 2);
  });

  test('Calculate with lowercase constants', () async {
    expect(await Engine.execute('pi * 2'), 3.1415926535897932 * 2);
  });

  test('Calculate with functions', () async {
    expect(await Engine.execute('POW(2,2)'), 4);
  });

  test('Calculate with two functions', () async {
    expect(await Engine.execute('POW(2,2)+SQRT(4)'), 6);
  });

  test('Calculate nested function call', () async {
    expect(await Engine.execute('SQRT(POW(2,2))'), 2);
  });

  test('Calculate nested function call with expression', () async {
    expect(await Engine.execute('SQRT(POW(2,2)+10)'), 3.7416573867739413);
  });

  test('Calculate two expressions', () async {
    expect(await Engine.execute('10;11'), 11);
  });
  test('Calculate two expressions with final semicolon', () async {
    expect(await Engine.execute('10;11;'), 11);
  });

  test('Test assignment', () async {
    expect(await Engine.execute('i:=42'), 42);
  });

  test('Test increment', () async {
    expect(await Engine.execute('i:=41;i:=i+1'), 42);
  });

  test('Test function definition', () async {
    expect((await Engine.execute('f(x):=x*2')).runtimeType, UserFunction);
  });

  test('Test user function', () async {
    expect((await Engine.execute('f(x):=x*2;f(2)')), 4);
  });

  test('Test recursion', () async {
    expect(
      (await Engine.execute(
        'fac(x) := IF x <= 1 THEN 1 ELSE x * fac(x-1);fac(3)',
      )),
      6,
    );
  });

  test('Test while loop', () async {
    expect((await Engine.execute('x := 0; WHILE x < 10 DO x := x + 1;x')), 10);
  });
}
