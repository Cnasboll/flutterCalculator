import 'dart:math';

import 'package:awesome_calculator/shql/parser/constants_set.dart';
import 'package:awesome_calculator/shql/parser/parse_tree.dart';

/// Represents a user-defined function with its arguments and body.
class UserFunction {
  final List<int> argumentIdentifiers;
  final ParseTree body;

  UserFunction({required this.argumentIdentifiers, required this.body});
}

class _Scope {
  final Map<int, dynamic> variables = {};
  final Map<int, UserFunction> userFunctions = {};
}

class Runtime {
  late final ConstantsTable<dynamic> _constants;
  late final ConstantsTable<String> _identifiers;
  final Map<String, Function()> _nullaryFunctions = {};
  late final Map<int, Function(dynamic p1)> _unaryFunctions;
  late final Map<int, Function(dynamic p1, dynamic p2)> _binaryFunctions;
  final List<_Scope> _scopeStack = [];
  final Map<int, Runtime> _subModelScopes = {};
  bool _readonly = false;

  Function(dynamic value)? printFunction;
  Future<String> Function()? readlineFunction;
  int get depth => _scopeStack.length;

  Runtime({
    ConstantsSet? constantsSet,
    required Map<int, Function(dynamic p1)> unaryFunctions,
    required Map<int, Function(dynamic p1, dynamic p2)> binaryFunctions,
  }) {
    _constants = constantsSet?.constants ?? ConstantsTable();
    _identifiers = constantsSet?.identifiers ?? ConstantsTable();
    _unaryFunctions = Map.from(unaryFunctions);
    _binaryFunctions = Map.from(binaryFunctions);
    _scopeStack.add(_Scope()); // Add the global scope
    hookUpConsole();
  }

  Runtime._readOnlyCopy(Runtime other) {
    _constants = other._constants;
    _identifiers = other._identifiers;
    _nullaryFunctions.addAll(other._nullaryFunctions);
    _unaryFunctions = Map.from(other._unaryFunctions);
    _binaryFunctions = Map.from(other._binaryFunctions);
    _scopeStack.add(other._scopeStack.first);
    _subModelScopes.addAll(other._subModelScopes);
    printFunction = other.printFunction;
    readlineFunction = other.readlineFunction;
    hookUpConsole();
    _readonly = true;
  }

  Runtime._subModel(Runtime parent) {
    _constants = ConstantsTable(parent: parent._constants.root());
    _identifiers = parent._identifiers;
    _scopeStack.add(_Scope()); // Sub-models have their own global scope
  }

  ConstantsTable<dynamic> get constants {
    return _constants;
  }

  ConstantsTable<String> get identifiers {
    return _identifiers;
  }

  (bool, String?) pushScope() {
    if (_scopeStack.length >= 100) {
      return (
        false,
        'Stack overflow. Too many nested function calls. 10 is the reasonable, chronological maximum allowed for a steam driven computing machine.',
      );
    }
    _scopeStack.add(_Scope());
    return (true, null);
  }

  void popScope() {
    if (_scopeStack.length > 1) {
      _scopeStack.removeLast();
    }
  }

  Runtime readOnlyChild() {
    final child = Runtime._readOnlyCopy(this);
    return child;
  }

  Runtime getSubModelScope(int identifier) {
    var scope = _subModelScopes[identifier];
    scope ??= _subModelScopes[identifier] = Runtime._subModel(this);
    return scope;
  }

  dynamic getVariable(int identifier) {
    for (final scope in _scopeStack.reversed) {
      if (scope.variables.containsKey(identifier)) {
        return scope.variables[identifier];
      }
    }
    return null;
  }

  void setVariable(int identifier, dynamic value) {
    if (readonly) {
      return;
    }

    // Try to find the variable in existing scopes to update it.
    for (final scope in _scopeStack.reversed) {
      if (scope.variables.containsKey(identifier)) {
        scope.variables[identifier] = value;
        return;
      }
    }

    // If not found, create it in the current scope.
    assignVariable(identifier, value);
  }

  void assignVariable(int identifier, dynamic value) {
    if (readonly) {
      return;
    }
    _scopeStack.last.variables[identifier] = value;
  }

  bool hasNullaryFunction(String name) {
    return _nullaryFunctions.containsKey(name);
  }

  Function()? getNullaryFunction(String name) {
    return _nullaryFunctions[name];
  }

  void setNullaryFunction(String name, dynamic Function() nullaryFunction) {
    _nullaryFunctions[name] = nullaryFunction;
  }

  bool hasUnaryFunction(int identifier) {
    return _unaryFunctions.containsKey(identifier);
  }

  Function(dynamic p1)? getUnaryFunction(int identifier) {
    return _unaryFunctions[identifier];
  }

  void setUnaryFunction(
    String name,
    dynamic Function(dynamic p1) unaryFunction,
  ) {
    _unaryFunctions[identifiers.include(name)] = unaryFunction;
  }

  Function(dynamic p1, dynamic p2)? getBinaryFunction(int identifier) {
    return _binaryFunctions[identifier];
  }

  bool hasBinaryFunction(int identifier) {
    return _binaryFunctions.containsKey(identifier);
  }

  void setBinaryFunction(
    String name,
    dynamic Function(dynamic p1, dynamic p2) binaryFunction,
  ) {
    _binaryFunctions[identifiers.include(name)] = binaryFunction;
  }

  bool hasVariable(int identifier) {
    for (final scope in _scopeStack.reversed) {
      if (scope.variables.containsKey(identifier)) {
        return true;
      }
    }
    return false;
  }

  UserFunction? getUserFunction(int identifier) {
    for (final scope in _scopeStack.reversed) {
      if (scope.userFunctions.containsKey(identifier)) {
        return scope.userFunctions[identifier];
      }
    }
    return null;
  }

  void setUserFunction(int identifier, UserFunction function) {
    if (readonly) {
      return;
    }
    // Always set in current scope. This allows shadowing.
    _scopeStack.last.userFunctions[identifier] = function;
  }

  bool hasUserFunction(int identifier) {
    for (final scope in _scopeStack.reversed) {
      if (scope.userFunctions.containsKey(identifier)) {
        return true;
      }
    }
    return false;
  }

  /// Resolves an identifier to its value, checking variables first (current scope, then parents),
  /// then constants (current scope, then parents). Returns (value, found) tuple.
  (dynamic, bool) resolveIdentifier(int identifier) {
    // Check variables first (mutable, shadows constants)
    final variable = getVariable(identifier);
    if (variable != null) {
      return (variable, true);
    }

    // Check constants in current scope
    var (constant, index) = _constants.getByIdentifier(identifier);
    if (constant != null || index != null) {
      return (constant, true);
    }

    return (null, false);
  }

  void print(dynamic value) {
    if (readonly) {
      return;
    }

    printFunction?.call(value);
  }

  Future<String> readLine() async {
    if (readonly) {
      return "";
    }

    return await readlineFunction?.call() ?? "";
  }

  void hookUpConsole() {
    setUnaryFunction("PRINT", print);
    setNullaryFunction("READLINE", readLine);
  }

    static ConstantsSet prepareConstantsSet() {
    var constantsSet = ConstantsSet();
    // Register mathematical constants
    for (var entry in allConstants.entries) {
      constantsSet.registerConstant(
        entry.value,
        constantsSet.includeIdentifier(entry.key),
      );
    }

    // Register mathematical functions
    for (var entry in unaryFunctions.entries) {
      constantsSet.includeIdentifier(entry.key);
    }
    for (var entry in binaryFunctions.entries) {
      constantsSet.includeIdentifier(entry.key);
    }
    return constantsSet;
  }

  static Runtime prepareRuntime([ConstantsSet? constantsSet]) {
    constantsSet ??= prepareConstantsSet();
    final unaryFns = <int, Function(dynamic p1)>{};
    for (final entry in unaryFunctions.entries) {
      unaryFns[constantsSet.includeIdentifier(entry.key)] = entry.value;
    }

    final binaryFns = <int, Function(dynamic p1, dynamic p2)>{};
    for (final entry in binaryFunctions.entries) {
      binaryFns[constantsSet.includeIdentifier(entry.key)] = entry.value;
    }

    var runtime = Runtime(
      constantsSet: constantsSet,
      unaryFunctions: unaryFns,
      binaryFunctions: binaryFns,
    );
    return runtime;
  }

  static final Map<String, dynamic> allConstants = {
    "ANSWER": 42,
    "TRUE": true,
    "FALSE": false,
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

  static final Map<String, dynamic Function(dynamic)> unaryFunctions = {
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

  static final Map<String, dynamic Function(dynamic, dynamic)> binaryFunctions =
      {
        "MIN": (a, b) => min(a, b),
        "MAX": (a, b) => max(a, b),
        "ATAN2": (a, b) => atan2(a, b),
        "POW": (a, b) => pow(a, b),
      };

  bool get readonly => _readonly;
}
