import 'package:awesome_calculator/shql/engine/engine.dart';
import 'package:awesome_calculator/shql/execution/apriori_execution_node.dart';
import 'package:awesome_calculator/shql/execution/execution_node.dart';
import 'package:awesome_calculator/shql/execution/lambdas/binary_lambda_execution_node.dart';
import 'package:awesome_calculator/shql/execution/lambdas/unary_lambda_execution_node.dart';
import 'package:awesome_calculator/shql/execution/lazy_child_execution_node.dart';
import 'package:awesome_calculator/shql/execution/artithmetic/multiplication_execution_node.dart';
import 'package:awesome_calculator/shql/parser/constants_set.dart';

class FunctionDefinitionExecutionNode extends LazyChildExecutionNode {
  FunctionDefinitionExecutionNode(super.node);

  @override
  ExecutionNode? createChildNode(ConstantsSet constantsSet) {
    var identifier = constantsSet.identifiers.constants[node.qualifier!];
    var (constant, index) = constantsSet.constants.getByIdentifier(
      node.qualifier!,
    );
    if (constant != null || index != null) {
      if (node.children.isNotEmpty) {
        var argumentCount = node.children.length;
        if (argumentCount == 1) {
          var lhs = Engine.createExecutionNode(node.children[0]);
          return MultiplicationExecutionNode(
            AprioriExecutionNode(constant),
            lhs!,
          );
        }
        error =
            "Attempt to use constant $identifier as a function: ($argumentCount) argument(s) given.";
        return null;
      }
      result = constant;
      return null;
    }

    var unaryFunction = Engine.unaryFunctions[identifier];
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

    var binaryFunction = Engine.binaryFunctions[identifier];
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
