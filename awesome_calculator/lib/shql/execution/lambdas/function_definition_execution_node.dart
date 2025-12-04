import 'package:awesome_calculator/shql/engine/engine.dart';
import 'package:awesome_calculator/shql/execution/execution_node.dart';
import 'package:awesome_calculator/shql/execution/lazy_execution_node.dart';
import 'package:awesome_calculator/shql/execution/runtime.dart';
import 'package:awesome_calculator/shql/tokenizer/token.dart';

class FunctionDefinitionExecutionNode extends LazyExecutionNode {
  FunctionDefinitionExecutionNode(super.node);

@override
  Future<bool> doTick(Runtime runtime) async {
    // Verify that node has exactly two children
    if (node.children.length != 2) {
      error =
          "Assignment operator requires exactly two operands, ${node.children.length} given.";
      return true;
    }

    // Verify that first child is an identifier
    if (node.children[0].symbol != Symbols.identifier) {
      error = "Left-hand side of assignment must be an identifier.";
      return true;
    }

    _rhs ??= Engine.createExecutionNode(node.children[1])!;

    if (!await _rhs!.tick(runtime)) {
      return false;
    }

    var identifier = node.children[0].qualifier!;
    runtime.setVariable(identifier, _rhs!.result);
    result = _rhs!.result;
    return true;
  }

  ExecutionNode? _rhs;
}