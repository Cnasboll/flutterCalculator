enum Symbols {
  none,
  //Operators:
  memberAccess,
  inOp,
  not,
  mul,
  div,
  mod,
  add,
  sub,
  lt,
  ltEq,
  gt,
  gtEq,
  eq,
  neq,
  match,
  notMatch,
  and,
  or,
  xor,
  unaryPlus,
  unaryMinus,
  identifier,
  list,
  integerLiteral,
  floatLiteral,
  stringLiteral,
  nullLiteral,
}

enum LiteralTypes {
  none,
  integerLiteral,
  floatLiteral,
  doubleQuotedStringLiteral,
  doubleQuotedRawStringLiteral,
  singleQuotedStringLiteral,
  singleQuotedRawStringLiteral,
}

enum TokenTypes {
  mul,
  div,
  mod,
  add,
  sub,
  lt,
  ltEq,
  eq,
  neq,
  gt,
  gtEq,
  match,
  not,
  notMatch,
  integerLiteral,
  floatLiteral,
  doubleQuotedStringLiteral,
  doubleQuotedRawStringLiteral,
  singleQuotedStringLiteral,
  singleQuotedRawStringLiteral,
  lPar,
  rPar,
  lBrack,
  rBrack,
  identifier,
  comma,
  dot,
}

enum Keywords {
  none,
  inKeyword,
  notKeyword,
  andKeyword,
  orKeyword,
  xorKeyword,
  nullKeyword,
}

class Token {
  String get lexeme {
    return _lexeme;
  }

  TokenTypes get tokenType {
    return _tokenType;
  }

  Keywords get keyword {
    return _keyword;
  }

  LiteralTypes get literalType {
    return _literalType;
  }

  int get operatorPrecedence {
    return _operatorPrecedence;
  }

  Symbols get symbol {
    return _symbol;
  }

  Token(
    this._lexeme,
    this._tokenType,
    this._keyword,
    this._literalType,
    this._operatorPrecedence,
    this._symbol,
  );

  factory Token.parser(TokenTypes tokenType, String lexeme) {
    Keywords keyword = Keywords.none;
    LiteralTypes literalType = LiteralTypes.none;
    int operatorPrecedence = -1;
    Symbols symbol = Symbols.none;

    switch (tokenType) {
      case TokenTypes.identifier:
        {
          keyword = _keywords[lexeme.toUpperCase()] ?? Keywords.none;
        }
        break;
      case TokenTypes.integerLiteral:
        literalType = LiteralTypes.integerLiteral;
        break;
      case TokenTypes.floatLiteral:
        literalType = LiteralTypes.floatLiteral;
        break;
      case TokenTypes.doubleQuotedStringLiteral:
        literalType = LiteralTypes.doubleQuotedStringLiteral;
        break;
      case TokenTypes.singleQuotedStringLiteral:
        literalType = LiteralTypes.singleQuotedStringLiteral;
        break;
      case TokenTypes.singleQuotedRawStringLiteral:
        literalType = LiteralTypes.singleQuotedRawStringLiteral;
        break;
      case TokenTypes.doubleQuotedRawStringLiteral:
        literalType = LiteralTypes.doubleQuotedRawStringLiteral;
        break;
      default:
        break;
    }
    var operatorSymbol = _keywordOpTable[keyword] ?? _symbolTable[tokenType];
    if (operatorSymbol != null) {
      symbol = operatorSymbol;
      operatorPrecedence = _operatorPrecendences[symbol]!;
    }
    return Token(
      lexeme,
      tokenType,
      keyword,
      literalType,
      operatorPrecedence,
      symbol,
    );
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is Token &&
          runtimeType == other.runtimeType &&
          _lexeme == other._lexeme &&
          _tokenType == other._tokenType;

  @override
  int get hashCode => Object.hash(_lexeme, _tokenType);

  String categorizeIdentifier() {
    if (isKeyword()) {
      return "Keyword $_lexeme";
    }

    if (isIdentifier()) {
      return "Identifer $_lexeme";
    }

    return "";
  }

  @override
  String toString() {
    var s = _tokenType == TokenTypes.identifier
        ? " ($categorizeIdentifier())"
        : "";
    return '$_tokenType "$_lexeme"$s';
  }

  bool isKeyword() {
    return _keyword != Keywords.none;
  }

  bool isIdentifier() {
    return _tokenType == TokenTypes.identifier && !isKeyword();
  }

  bool takesPrecedence(Token rhs) {
    return operatorPrecedence < rhs.operatorPrecedence;
  }

  bool isOperator() {
    return _operatorPrecedence >= 0;
  }

  static Map<String, Keywords> getKeywords() {
    return {
      "IN": Keywords.inKeyword,
      "FINNS_I": Keywords.inKeyword,
      "NOT": Keywords.notKeyword,
      "INTE": Keywords.notKeyword,
      "AND": Keywords.andKeyword,
      "OCH": Keywords.andKeyword,
      "OR": Keywords.orKeyword,
      "ELLER": Keywords.orKeyword,    
      "XOR": Keywords.xorKeyword,
      "ANTINGEN_ELLER": Keywords.xorKeyword,
      "NULL": Keywords.nullKeyword,
    };
  }

  static Map<Symbols, int> getOperatorPrecendences() {
    var precedence = 0;
    return {
      // Member access
      Symbols.memberAccess: precedence++,
      // In [array]
      Symbols.inOp: precedence,
      // Not
      Symbols.not: precedence++,

      // Multiplication, division and remainder
      Symbols.mul: precedence,
      Symbols.div: precedence,
      Symbols.mod: precedence++,

      // Addition and subtraction
      Symbols.add: precedence,
      Symbols.sub: precedence++,

      // Relational operators
      Symbols.lt: precedence,
      Symbols.ltEq: precedence,
      Symbols.gt: precedence,
      Symbols.gtEq: precedence++,

      // Equalities
      Symbols.eq: precedence,
      Symbols.neq: precedence,

      // Pattern matching
      Symbols.match: precedence,
      Symbols.notMatch: precedence++,

      // Conjunctions
      Symbols.and: precedence++,

      // Disjunctions
      Symbols.or: precedence,
      Symbols.xor: precedence++,

      Symbols.nullLiteral: precedence,
    };
  }

  static Map<TokenTypes, Symbols> getSymbolTable() {
    return {
      TokenTypes.dot: Symbols.memberAccess,
      TokenTypes.mul: Symbols.mul,
      TokenTypes.div: Symbols.div,
      TokenTypes.mod: Symbols.mod,
      TokenTypes.add: Symbols.add,
      TokenTypes.sub: Symbols.sub,
      TokenTypes.not: Symbols.not,
      TokenTypes.lt: Symbols.lt,
      TokenTypes.ltEq: Symbols.ltEq,
      TokenTypes.eq: Symbols.eq,
      TokenTypes.neq: Symbols.neq,
      TokenTypes.gt: Symbols.gt,
      TokenTypes.gtEq: Symbols.gtEq,
      TokenTypes.match: Symbols.match,
      TokenTypes.notMatch: Symbols.notMatch,
    };
  }

  static Map<Keywords, Symbols> getKeywordOpTable() {
    return {
      Keywords.inKeyword: Symbols.inOp,
      Keywords.notKeyword: Symbols.not,
      Keywords.andKeyword: Symbols.and,
      Keywords.orKeyword: Symbols.or,
      Keywords.xorKeyword: Symbols.xor,
      Keywords.nullKeyword: Symbols.nullLiteral,
    };
  }

  final String _lexeme;
  final TokenTypes _tokenType;
  static final Map<String, Keywords> _keywords = getKeywords();
  static final Map<Symbols, int> _operatorPrecendences =
      getOperatorPrecendences();
  static final Map<TokenTypes, Symbols> _symbolTable = getSymbolTable();
  static final Map<Keywords, Symbols> _keywordOpTable = getKeywordOpTable();
  final Keywords _keyword;
  final LiteralTypes _literalType;
  final int _operatorPrecedence;
  final Symbols _symbol;
}
