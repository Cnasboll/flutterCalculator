class ConstantsTable<T> {
  ConstantsTable({ConstantsTable<T>? parent}) : _parent = parent;

  // Deep copy constructor
  ConstantsTable.copy(ConstantsTable<T> other, {ConstantsTable<T>? parent})
    : _parent = parent {
    // Deep copy all the collections
    _constants.addAll(other._constants);
    _index.addAll(other._index);
    _indexByIdentifier.addAll(other._indexByIdentifier);
  }

  int include(T value) {
    var index = _index[value];

    if (index == null) {
      index = _index[value] = _constants.length;
      _constants.add(value);
    }
    return index;
  }

  int register(T value, int identifier) {
    var index = _index[value];

    if (index == null) {
      index = _index[value] = _constants.length;
      _constants.add(value);
    }
    _indexByIdentifier[identifier] = index;
    return index;
  }

  (T?, int?) getByIdentifier(int identifier) {
    var index = _indexByIdentifier[identifier];
    if (index == null) {
      if (_parent != null) {
        return _parent.getByIdentifier(identifier);
      }
      return (null, null);
    }
    return (_constants[index], index);
  }

  List<T> get constants {
    return _constants;
  }

  ConstantsTable<T>? root() {
    if (_parent == null) {
      return this;
    }

    return _parent.root();
  }

  final List<T> _constants = [];
  final Map<T, int> _index = {};
  final Map<int, int> _indexByIdentifier = {};
  final ConstantsTable<T>? _parent;
}

class ConstantsSet {
  ConstantsSet()
    : _constants = ConstantsTable(),
      _identifiers = ConstantsTable();

  ConstantsSet._child(ConstantsSet parent)
    : _constants = ConstantsTable<dynamic>.copy(parent._constants),
      _identifiers = parent._identifiers;

  ConstantsSet._subModel(ConstantsSet parent)
    : _constants = ConstantsTable(parent: parent._constants.root()),
      _identifiers = parent._identifiers;

  ConstantsTable<dynamic> get constants {
    return _constants;
  }

  ConstantsTable<String> get identifiers {
    return _identifiers;
  }

  ConstantsSet createChild() {
    return ConstantsSet._child(this);
  }

  ConstantsSet getSubModelScope(int identifier) {
    var scope = _subModelScopes[identifier];
    scope ??= _subModelScopes[identifier] = ConstantsSet._subModel(this);
    return scope;
  }

  void registerEnum<T extends Enum>(Iterable<T> values) {
    for (var value in values) {
      constants.register(
        value.index,
        identifiers.include(camelCaseToSnakeCase(value.name)),
      );
    }
  }

  String camelCaseToSnakeCase(String camelCase) {
    if (camelCase.isEmpty) {
      return camelCase;
    }

    final buffer = StringBuffer();

    bool? upperCase;
    for (var char in camelCase.runes.map((r) => String.fromCharCode(r))) {
      bool? wasUpperCase = upperCase;
      if (char.toUpperCase() == char && char.toLowerCase() != char) {
        // Encountered an uppercase letter
        upperCase = true;
      } else {
        upperCase = false;
      }

      if (wasUpperCase == false && upperCase) {
        // Transition from lower to upper case
        if (buffer.isNotEmpty) {
          buffer.write('_');
        }
      }
      buffer.write(char.toUpperCase());
    }

    return buffer.toString();
  }

  final ConstantsTable<dynamic> _constants;
  final ConstantsTable<String> _identifiers;
  final Map<int, ConstantsSet> _subModelScopes = {};
}
