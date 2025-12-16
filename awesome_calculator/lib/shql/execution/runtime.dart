import 'dart:math';

import 'package:awesome_calculator/shql/engine/cancellation_token.dart';
import 'package:awesome_calculator/shql/execution/execution_node.dart';
import 'package:awesome_calculator/shql/parser/constants_set.dart';
import 'package:awesome_calculator/shql/parser/parse_tree.dart';

/// Represents a user-defined function with its arguments and body.
class UserFunction {
  final String? name;
  final List<int> argumentIdentifiers;
  final Scope scope;
  final ParseTree body;

  UserFunction({
    this.name,
    required this.argumentIdentifiers,
    required this.scope,
    required this.body,
  });
}

class Constant {
  final dynamic value;
  final int identifier;

  Constant(this.value, this.identifier);
}

enum BreakState { none, breaked, continued }

class BreakTarget {
  BreakState _state = BreakState.none;
  void breakExecution() {
    _state = BreakState.breaked;
  }

  void continueExecution() {
    _state = BreakState.continued;
  }

  bool clearContinued() {
    var continued = _state == BreakState.continued;
    if (continued) {
      _state = BreakState.none;
    }
    return continued;
  }

  Future<bool> check(CancellationToken? cancellationToken) async {
    if (await cancellationToken?.check() ?? false) {
      return true;
    }
    return _state == BreakState.breaked;
  }
}

class ReturnTarget {
  bool _returned = false;
  bool _hasReturnValue = false;

  dynamic _returnValue;

  dynamic get returnValue => _returnValue;
  bool get hasReturnValue => _hasReturnValue;

  void returnNothing() {
    _returned = true;
    _hasReturnValue = false;
    _returnValue = null;
  }

  void returnAValue(dynamic returnValue) {
    _returned = true;
    _hasReturnValue = true;
    _returnValue = returnValue;
  }

  Future<bool> check(CancellationToken? cancellationToken) async {
    if (await cancellationToken?.check() ?? false) {
      return true;
    }
    return _returned;
  }
}

class Thread {
  final int id;
  final List<ExecutionNode> executionStack = [];
  final List<BreakTarget> _breakTargets = [];
  final List<ReturnTarget> _returnTargets = [];
  Thread({required this.id});
  bool get isIdle => executionStack.isEmpty;
  bool get isRunning => executionStack.isNotEmpty;
  ExecutionNode? get currentNode => isRunning ? executionStack.last : null;

  ExecutionNode? popNode() {
    if (isRunning) {
      return executionStack.removeLast();
    }
    return null;
  }

  ExecutionNode? onExecutionNodeComplete(ExecutionNode executionNode) {
    if (isRunning) {
      error ??= executionNode.error;
      result = executionNode.result;
      return popNode();
    }
    return null;
  }

  void pushNode(ExecutionNode executionNode) {
    executionStack.add(executionNode);
  }

  void reset() {
    error = null;
    result = null;
    clearExecutionStack();
    clearBreakTargets();
    clearReturnTargets();
  }

  void clearExecutionStack() {
    executionStack.clear();
  }

  BreakTarget pushBreakTarget() {
    var breakTarget = BreakTarget();
    _breakTargets.add(breakTarget);
    return breakTarget;
  }

  void popBreakTarget() {
    if (_breakTargets.isNotEmpty) {
      _breakTargets.removeLast();
    }
  }

  void breakCurrentExecution() {
    if (_breakTargets.isNotEmpty) {
      _breakTargets.last.breakExecution();
    }
  }

  BreakTarget? get currentBreakTarget {
    if (_breakTargets.isNotEmpty) {
      return _breakTargets.last;
    }
    return null;
  }

  BreakState currentExecutionBreakState() {
    if (_breakTargets.isNotEmpty) {
      return _breakTargets.last._state;
    }
    return BreakState.none;
  }

  void clearBreakTargets() {
    _breakTargets.clear();
  }

  (ReturnTarget?, String?) pushReturnTarget() {
    if (_returnTargets.length >= 10) {
      return (
        null,
        'Stack overflow. Too many nested function calls. 10 is the reasonable, chronological maximum allowed for a steam driven computing machine.',
      );
    }
    var returnTarget = ReturnTarget();
    _returnTargets.add(returnTarget);
    return (returnTarget, null);
  }

  void popReturnTarget() {
    if (_returnTargets.isNotEmpty) {
      _returnTargets.removeLast();
    }
  }

  ReturnTarget? get currentReturnTarget {
    if (_returnTargets.isNotEmpty) {
      return _returnTargets.last;
    }
    return null;
  }

  bool currentFunctionReturned() {
    if (_returnTargets.isNotEmpty) {
      return _returnTargets.last._returned;
    }
    return false;
  }

  void clearReturnTargets() {
    _returnTargets.clear();
  }

  Future<bool> check(CancellationToken? cancellationToken) async {
    if (await cancellationToken?.check() ?? false) {
      return true;
    }
    if (currentExecutionBreakState() != BreakState.none) {
      return true;
    }
    return currentFunctionReturned();
  }

  Future<bool> tick(
    Runtime runtime, [
    CancellationToken? cancellationToken,
  ]) async {
    while ((cancellationToken == null || !await cancellationToken.check())) {
      var currentNode = executionStack.isNotEmpty ? executionStack.last : null;
      if (currentNode == null) {
        return true;
      }
      var tickResult = await currentNode.tick(runtime, cancellationToken);
      if (tickResult == TickResult.iterated) {
        return false;
      }
    }
    return true;
  }

  String? error;
  dynamic result;
  dynamic getResult() {
    return result;
  }
}

class Object {
  final Map<int, dynamic> members = {};
  final Map<int, dynamic> variables = {};
  final Map<int, UserFunction> userFunctons = {};

  dynamic resolveIdentifier(int identifier) {
    return members[identifier];
  }

  bool hasMember(int identifier) {
    return members.containsKey(identifier);
  }

  void setVariable(int identifier, dynamic value) {
    members[identifier] = variables[identifier] = value;
    userFunctons.remove(identifier);
  }

  UserFunction defineUserFunction(int identifier, UserFunction userFunction) {
    members[identifier] = userFunctons[identifier] = userFunction;
    variables.remove(identifier);
    return userFunction;
  }

  Object clone() {
    var newObject = Object();
    newObject.members.addAll(members);
    newObject.variables.addAll(variables);
    newObject.userFunctons.addAll(userFunctons);
    return newObject;
  }
}

class Scope {
  Object members;
  ConstantsTable<dynamic>? constants;
  Scope? parent;
  Scope(this.members, {this.constants, this.parent});

  (dynamic, Scope?, bool) resolveIdentifier(int identifier) {
    Scope? current = this;
    while (current != null) {
      var member = current.members.resolveIdentifier(identifier);
      if (member != null) {
        return (member, current, false);
      }
      current = current.parent;
    }

    if (constants != null) {
      var (value, index) = constants!.getByIdentifier(identifier);
      if (index != null) {
        return (value, this, true);
      }
    }

    return (null, null, false);
  }

  bool hasMember(int identifier) {
    Scope? current = this;
    while (current != null) {
      if (current.members.hasMember(identifier)) {
        return true;
      }
      current = current.parent;
    }

    if (constants != null) {
      var (value, index) = constants!.getByIdentifier(identifier);
      return index != null;
    }
    return false;
  }

  (Scope, String?) setVariable(int identifier, dynamic value) {
    var (existingValue, containingScope, isConstant) = resolveIdentifier(
      identifier,
    );
    if (existingValue != null && isConstant) {
      // Cannot modify constant
      return (containingScope!, "Cannot modify constant");
    }
    containingScope ??= this;
    containingScope.members.setVariable(identifier, value);
    return (containingScope, null);
  }

  (Scope, UserFunction, String?) defineUserFunction(
    int identifier,
    UserFunction userFunction,
  ) {
    var (existingValue, containingScope, isConstant) = resolveIdentifier(
      identifier,
    );
    if (isConstant) {
      // Cannot modify constant
      return (
        containingScope!,
        userFunction,
        "Cannot shadow constant with function",
      );
    }

    containingScope ??= this;
    return (
      containingScope,
      containingScope.members.defineUserFunction(identifier, userFunction),
      null,
    );
  }

  Scope clone() {
    Scope? current = this;
    Scope? tail;
    Scope? head;
    while (current != null) {
      var newNode = Scope(
        current.members.clone(),
        constants: current.constants,
      );
      if (head == null) {
        head = tail = newNode;
      } else {
        tail!.parent = newNode;
        tail = newNode;
      }
      current = current.parent;
    }
    return head!;
  }
}

class Runtime {
  late final ConstantsTable<String> _identifiers;
  final Map<String, Function()> _nullaryFunctions = {};
  late final Map<int, Function(dynamic p1)> _unaryFunctions;
  late final Map<int, Function(dynamic p1, dynamic p2)> _binaryFunctions;
  late final Thread mainThread;
  late final Scope globalScope;
  final Map<int, Runtime> _subModelScopes = {};
  bool _sandboxed = false;

  Function(dynamic value)? printFunction;
  Future<String> Function()? readlineFunction;
  Future<String> Function(String prompt)? promptFunction;
  Future<void> Function()? clsFunction;
  Future<void> Function()? hideGraphFunction;
  Future<void> Function(dynamic, dynamic)? plotFunction;

  Runtime({
    ConstantsSet? constantsSet,
    required Map<int, Function(dynamic p1)> unaryFunctions,
    required Map<int, Function(dynamic p1, dynamic p2)> binaryFunctions,
  }) {
    _identifiers = constantsSet?.identifiers ?? ConstantsTable();
    _unaryFunctions = Map.from(unaryFunctions);
    _binaryFunctions = Map.from(binaryFunctions);
    mainThread = Thread(id: 0);
    globalScope = Scope(
      Object(),
      constants: constantsSet?.constants ?? ConstantsTable(),
    );
    hookUpConsole();
  }

  Runtime._sandbox(Runtime other) {
    _identifiers = other._identifiers;
    _nullaryFunctions.addAll(other._nullaryFunctions);
    _unaryFunctions = Map.from(other._unaryFunctions);
    _binaryFunctions = Map.from(other._binaryFunctions);
    mainThread = Thread(id: 0);
    globalScope = other.globalScope.clone();
    _subModelScopes.addAll(other._subModelScopes);
    printFunction = other.printFunction;
    readlineFunction = other.readlineFunction;
    promptFunction = other.promptFunction;
    clsFunction = other.clsFunction;
    hideGraphFunction = other.hideGraphFunction;
    plotFunction = other.plotFunction;
    hookUpConsole();
    _sandboxed = true;
  }

  Runtime._subModel(Runtime parent) {
    mainThread = parent.mainThread;
    globalScope = Scope(Object(), constants: parent.globalScope.constants);
    _identifiers = parent._identifiers;
    // Sub-models have their own global scope
  }

  ConstantsTable<String> get identifiers {
    return _identifiers;
  }

  Runtime sandbox() {
    final child = Runtime._sandbox(this);
    return child;
  }

  Runtime getSubModelScope(int identifier) {
    var scope = _subModelScopes[identifier];
    scope ??= _subModelScopes[identifier] = Runtime._subModel(this);
    return scope;
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

  /*bool hasVariable(int identifier) {
    for (final scope in _scopeStack.reversed) {
      if (scope.variables.containsKey(identifier)) {
        return true;
      }
    }
    return false;
  }

  (UserFunction?, int?) getUserFunction(int identifier) {
    for (var i = _scopeStack.length - 1; i >= 0; i--) {
      final scope = _scopeStack[i];
      if (scope.userFunctions.containsKey(identifier)) {
        return (scope.userFunctions[identifier], i);
      }
    }
    return (null, null);
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
  /// then constants (current scope, then parents). Returns (value, found, scopeIndex) tuple.
  (dynamic, bool, int?) resolveIdentifier(int identifier) {
    // Check variables first (mutable, shadows constants)
    final (variable, scopeIndex) = getVariable(identifier);
    if (variable != null) {
      return (variable, true, scopeIndex);
    }

    // Check constants in current scope
    var (constant, index) = _constants.getByIdentifier(identifier);
    if (constant != null || index != null) {
      return (constant, true, null); // Constants don't have a scope index
    }

    return (null, false, null);
  }*/

  void print(dynamic value) {
    if (readonly) {
      return;
    }

    printFunction?.call(value);
  }

  Future<String> prompt(dynamic prompt) async {
    if (readonly) {
      return "";
    }

    return await promptFunction?.call(prompt) ?? "";
  }

  Future<String> readLine() async {
    if (readonly) {
      return "";
    }

    return await readlineFunction?.call() ?? "";
  }

  Future<void> plot(dynamic xVector, dynamic yVector) async {
    if (readonly) {
      return;
    }
    return await plotFunction?.call(xVector, yVector);
  }

  Future<void> cls() async {
    if (readonly) {
      return;
    }

    await clsFunction?.call();
  }

  Future<void> hideGraph() async {
    if (readonly) {
      return;
    }

    await hideGraphFunction?.call();
  }

  extern(name, args) {
    /*var nullaryFunction  = nullaryFunctions[name];
    if (nullaryFunction != null) {
      return nullaryFunction();
    }*/
    var unaryFunction = unaryFunctions[name];
    if (unaryFunction != null) {
      if (args is List && args.length == 1) {
        return unaryFunction(args[0]);
      }
    }
    var binaryFunction = binaryFunctions[name];
    if (binaryFunction != null) {
      if (args is List && args.length == 2) {
        return binaryFunction(args[0], args[1]);
      }
    }
    return null;
  }

  void hookUpConsole() {
    setUnaryFunction("PRINT", print);
    setUnaryFunction("PROMPT", prompt);
    setNullaryFunction("READLINE", readLine);
    setBinaryFunction("_DISPLAY_GRAPH", plot);
    setNullaryFunction("CLS", cls);
    setNullaryFunction("HIDE_GRAPH", hideGraph);
    setBinaryFunction("_EXTERN", extern);
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
    /*for (var entry in unaryFunctions.entries) {
      constantsSet.includeIdentifier(entry.key);
    }
    for (var entry in binaryFunctions.entries) {
      constantsSet.includeIdentifier(entry.key);
    }*/
    return constantsSet;
  }

  static Runtime prepareRuntime([ConstantsSet? constantsSet]) {
    constantsSet ??= prepareConstantsSet();
    final unaryFns = <int, Function(dynamic p1)>{};
    /*for (final entry in unaryFunctions.entries) {
      unaryFns[constantsSet.includeIdentifier(entry.key)] = entry.value;
    }*/

    final binaryFns = <int, Function(dynamic p1, dynamic p2)>{};
    /*for (final entry in binaryFunctions.entries) {
      binaryFns[constantsSet.includeIdentifier(entry.key)] = entry.value;
    }*/

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
    "INT": (a) {
      if (a is int) {
        return a;
      }
      if (a is String) {
        return int.tryParse(a) ?? 0;
      }
      if (a is double) {
        return a.toInt();
      }
      return a;
    },
    "DOUBLE": (a) {
      if (a is double) {
        return a;
      }
      if (a is String) {
        return double.tryParse(a) ?? 0.0;
      }
      if (a is int) {
        return a.toDouble();
      }
      return a;
    },
    "STRING": (a) => a.toString(),
    "ROUND": (a) => a is double ? a.round() : a,
    "LENGTH": (a) {
      if (a is String) {
        return a.length;
      }
      if (a is List) {
        return a.length;
      }
      return 0;
    },
  };

  static final Map<String, dynamic Function(dynamic, dynamic)> binaryFunctions =
      {
        "MIN": (a, b) => min(a, b),
        "MAX": (a, b) => max(a, b),
        "ATAN2": (a, b) => atan2(a, b),
        "POW": (a, b) => pow(a, b),
        "DIM": (a, b) {
          if (a is List && b is num) {
            while (a.length > b) {
              a.removeLast();
            }
            while (a.length < b) {
              a.add(0);
            }
          }
          return a;
        },
      };

  bool get readonly => _sandboxed;
}
