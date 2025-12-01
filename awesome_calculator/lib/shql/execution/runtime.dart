import 'package:awesome_calculator/shql/parser/constants_set.dart';

class Runtime {
  late ConstantsTable<dynamic> _constants;
  late ConstantsTable<String> _identifiers;
  Map<String, Function()> _nullaryFunctions = {};
  late Map<String, Function(dynamic p1)> _unaryFunctions;
  late Map<String, Function(dynamic p1, dynamic p2)> _binaryFunctions;
  late Map<int, dynamic> _variables;
  late Runtime? _parent;
  final Map<int, Runtime> _subModelScopes = {};

  late bool _readonly = false;
  Function(dynamic value)? printFunction;
  Future<String> Function()? readlineFunction;

  Runtime({
    ConstantsSet? constantsSet,
    required Map<String, Function(dynamic p1)> unaryFunctions,
    required Map<String, Function(dynamic p1, dynamic p2)> binaryFunctions,
  }) {
    _constants = constantsSet != null
        ? constantsSet.constants
        : ConstantsTable();
    _identifiers = constantsSet != null
        ? constantsSet.identifiers
        : ConstantsTable();
    _unaryFunctions = Map<String, dynamic Function(dynamic)>.from(
      unaryFunctions,
    );
    _binaryFunctions = Map<String, dynamic Function(dynamic, dynamic)>.from(
      binaryFunctions,
    );
    hookUpConsole();
    _variables = {};
    _parent = null;
  }

  Runtime._child(Runtime parent, [bool readOnly = false]) {
    _constants = parent._constants;
    _identifiers = parent._identifiers;
    _nullaryFunctions = Map<String, dynamic Function()>.from(
      parent._nullaryFunctions,
    );
    _unaryFunctions = Map<String, dynamic Function(dynamic)>.from(
      parent._unaryFunctions,
    );
    _binaryFunctions = Map<String, dynamic Function(dynamic, dynamic)>.from(
      parent._binaryFunctions,
    );
    hookUpConsole();
    _variables = {};
    _parent = parent;
    _readonly = readOnly;
  }

  Runtime._subModel(Runtime parent) {
    _constants = ConstantsTable(parent: parent._constants.root());
    _identifiers = parent._identifiers;
    _variables = parent._variables;
    _parent = null;
  }

  ConstantsTable<dynamic> get constants {
    return _constants;
  }

  ConstantsTable<String> get identifiers {
    return _identifiers;
  }

  Runtime createChild({bool readOnly = false}) {
    return Runtime._child(this, readOnly);
  }

  Runtime getSubModelScope(int identifier) {
    var scope = _subModelScopes[identifier];
    scope ??= _subModelScopes[identifier] = Runtime._subModel(this);
    return scope;
  }

  dynamic getVariable(int identifier) {
    if (_variables.containsKey(identifier)) {
      return _variables[identifier];
    }
    // Check parent scope
    return _parent?.getVariable(identifier);
  }

  void setVariable(int identifier, dynamic value) {
    if (_readonly) {
      return;
    }

    // Always set in current scope (no shadowing unless it's a function argument)
    if (_variables.containsKey(identifier)) {
      _variables[identifier] = value;
    } else if (_parent?.hasVariable(identifier) == true) {
      // Variable exists in parent scope, update it there
      _parent?.setVariable(identifier, value);
    } else {
      // New variable, create in current scope
      _variables[identifier] = value;
    }
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

  bool hasUnaryFunction(String name) {
    return _unaryFunctions.containsKey(name);
  }

  Function(dynamic p1)? getUnaryFunction(String name) {
    return _unaryFunctions[name];
  }

  void setUnaryFunction(
    String name,
    dynamic Function(dynamic p1) unaryFunction,
  ) {
    _unaryFunctions[name] = unaryFunction;
  }

  Function(dynamic p1, dynamic p2)? getBinaryFunction(String name) {
    return _binaryFunctions[name];
  }

  bool hasBinaryFunction(String name) {
    return _binaryFunctions.containsKey(name);
  }

  void setBinaryFunction(
    String name,
    dynamic Function(dynamic p1, dynamic p2) binaryFunction,
  ) {
    _binaryFunctions[name] = binaryFunction;
  }

  bool hasVariable(int identifier) {
    if (_variables.containsKey(identifier)) {
      return true;
    }
    // Check parent scope
    return _parent?.hasVariable(identifier) ?? false;
  }

  /// Resolves an identifier to its value, checking variables first (current scope, then parents),
  /// then constants (current scope, then parents). Returns (value, found) tuple.
  (dynamic, bool) resolveIdentifier(int identifier) {
    // Check variables first (mutable, shadows constants)
    if (_variables.containsKey(identifier)) {
      return (_variables[identifier], true);
    }

    // Check constants in current scope
    var (constant, index) = _constants.getByIdentifier(identifier);
    if (constant != null || index != null) {
      return (constant, true);
    }

    // Check parent scope recursively
    return _parent?.resolveIdentifier(identifier) ?? (null, false);
  }

  Runtime? readOnlyChild() => createChild(readOnly: true);

  void print(dynamic value) {
    if (_readonly) {
      return;
    }

    if (printFunction != null) {
      printFunction!(value);
      return;
    }
    if (_parent != null) {
      _parent!.print(value);
    }
  }

  Future<String> readLine() async {
    if (_readonly) {
      return "";
    }

    if (readlineFunction != null) {
      return await readlineFunction!();
    }
    if (_parent != null) {
      return _parent!.readLine();
    }
    return "";
  }

  void hookUpConsole() {
    setUnaryFunction("PRINT", print);
    setNullaryFunction("READLINE", readLine);
  }

  bool get readonly => _readonly;
}
