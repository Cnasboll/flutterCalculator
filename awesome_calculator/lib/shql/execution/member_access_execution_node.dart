import 'package:awesome_calculator/shql/engine/engine.dart';
import 'package:awesome_calculator/shql/execution/lazy_execution_node.dart';
import 'package:awesome_calculator/shql/parser/constants_set.dart';
import 'package:awesome_calculator/shql/parser/parse_tree.dart';
import 'package:awesome_calculator/shql/tokenizer/token.dart';

class MemberAccessExecutionNode extends LazyExecutionNode {
  MemberAccessExecutionNode(super.node);

  @override
  bool doTick(ConstantsSet constantsSet) {
    if (node.children.length != 2) {
      error = 'Member access must have exactly 2 children';
      return true;
    }

    var leftChild = node.children[0];
    var rightChild = node.children[1];

    // Right side must always be an identifier
    if (rightChild.symbol != Symbols.identifier) {
      error = 'Right side of member access must be an identifier';
      return true;
    }

    ConstantsSet targetScope;

    if (leftChild.symbol == Symbols.identifier) {
      // Simple case: a.b
      targetScope = constantsSet.getSubModelScope(leftChild.qualifier!);
    } else if (leftChild.symbol == Symbols.memberAccess) {
      // Recursive case: a.b.c (where a.b is another memberAccess)
      // We need to resolve the left side to get the appropriate scope
      targetScope = _resolveMemberAccessToScope(leftChild, constantsSet);
    } else {
      error =
          'Left side of member access must be an identifier or another member access';
      return true;
    }

    // Now evaluate the right identifier in the target scope
    var rightNode = Engine.createExecutionNode(rightChild);
    if (rightNode == null) {
      error = 'Failed to create execution node for right side of member access';
      return true;
    }

    // Tick the right node until complete
    while (!rightNode.tick(targetScope)) {}

    if (rightNode.error != null) {
      error = rightNode.error;
      return true;
    }

    result = rightNode.result;
    return true;
  }

  static ConstantsSet _resolveMemberAccessToScope(
    ParseTree memberAccessTree,
    ConstantsSet constantsSet,
  ) {
    if (memberAccessTree.symbol != Symbols.memberAccess) {
      throw RuntimeException('Expected member access parse tree');
    }

    var leftChild = memberAccessTree.children[0];
    var rightChild = memberAccessTree.children[1];

    if (rightChild.symbol != Symbols.identifier) {
      throw RuntimeException(
        'Right side of member access must be an identifier',
      );
    }

    ConstantsSet intermediateScope;

    if (leftChild.symbol == Symbols.identifier) {
      // Base case: a.b - get sub-scope of a
      intermediateScope = constantsSet.getSubModelScope(leftChild.qualifier!);
    } else if (leftChild.symbol == Symbols.memberAccess) {
      // Recursive case: resolve a.b first, then get its sub-scope
      intermediateScope = _resolveMemberAccessToScope(leftChild, constantsSet);
    } else {
      throw RuntimeException(
        'Left side of member access must be an identifier or another member access',
      );
    }

    // Now get the sub-scope of the right identifier within the intermediate scope
    return intermediateScope.getSubModelScope(rightChild.qualifier!);
  }
}
