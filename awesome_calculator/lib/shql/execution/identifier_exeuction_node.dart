import 'package:awesome_calculator/shql/engine/engine.dart';
import 'package:awesome_calculator/shql/execution/apriori_execution_node.dart';
import 'package:awesome_calculator/shql/execution/execution_node.dart';
import 'package:awesome_calculator/shql/execution/lambdas/binary_lambda_execution_node.dart';
import 'package:awesome_calculator/shql/execution/lambdas/nullary_lambda_execution_node.dart';
import 'package:awesome_calculator/shql/execution/lambdas/unary_lambda_execution_node.dart';
import 'package:awesome_calculator/shql/execution/lazy_child_execution_node.dart';
import 'package:awesome_calculator/shql/execution/artithmetic/multiplication_execution_node.dart';
import 'package:awesome_calculator/shql/execution/runtime.dart';

class IdentifierExecutionNode extends LazyChildExecutionNode {
  IdentifierExecutionNode(super.node);

  @override
  ExecutionNode? createChildNode(Runtime runtime) {
    var identifier = runtime.identifiers.constants[node.qualifier!];

    // Try to resolve identifier (variables shadow constants, walks parent chain)
    var (value, found) = runtime.resolveIdentifier(node.qualifier!);
    if (found) {
      if (node.children.isNotEmpty) {
        var argumentCount = node.children.length;
        if (argumentCount == 1) {
          var lhs = Engine.createExecutionNode(node.children[0]);
          return MultiplicationExecutionNode(AprioriExecutionNode(value), lhs!);
        }
        error =
            "Attempt to use value $identifier as a function: ($argumentCount) argument(s) given.";
        return null;
      }
      result = value;
      return null;
    }

    var nullaryFunction = runtime.getNullaryFunction(identifier);
    if (nullaryFunction != null) {
      if (node.children.isNotEmpty) {
        var argumentCount = node.children.length;
        error =
            "Function $identifier() takes 0 arguments, $argumentCount given.";
        return null;
      }
      return NullaryLambdaExecutionNode(
        nullaryFunction,
      );
    }

    var unaryFunction = runtime.getUnaryFunction(identifier);
    if (unaryFunction != null) {
      if (node.children.length != 1) {
        var argumentCount = node.children.length;
        error =
            "Function $identifier() takes 1 argument, $argumentCount given.";
        return null;
      }
      return UnaryLambdaExecutionNode(
        unaryFunction,
        Engine.createExecutionNode(node.children.first)!,
      );
    }

    var binaryFunction = runtime.getBinaryFunction(identifier);
    if (binaryFunction != null) {
      if (node.children.length != 2) {
        var argumentCount = node.children.length;
        error =
            "Function $identifier() takes 2 arguments, $argumentCount given.";
        return null;
      }

      return BinaryLambdaExecutionNode(
        binaryFunction,
        Engine.createExecutionNode(node.children[0])!,
        Engine.createExecutionNode(node.children[1])!,
      );
    }

    if (node.children.isNotEmpty) {
      error = 'Unidentified identifier "$identifier" used as a function.';
      return null;
    }
    error = '''Unidentified identifier "$identifier" used as a constant.

Hint: enclose strings in quotes, e.g.          name ~ "Batman"       rather than:     name ~ Batman

''';
    return null;
  }
}
