import 'package:awesome_calculator/shql/engine/engine.dart';
import 'package:awesome_calculator/shql/execution/apriori_execution_node.dart';
import 'package:awesome_calculator/shql/execution/execution_node.dart';
import 'package:awesome_calculator/shql/execution/indexer_execution_node.dart';
import 'package:awesome_calculator/shql/execution/lambdas/binary_lambda_execution_node.dart';
import 'package:awesome_calculator/shql/execution/lambdas/lambda_expression_execution_node.dart';
import 'package:awesome_calculator/shql/execution/lambdas/nullary_lambda_execution_node.dart';
import 'package:awesome_calculator/shql/execution/lambdas/unary_lambda_execution_node.dart';
import 'package:awesome_calculator/shql/execution/lambdas/user_function_execution_node.dart';
import 'package:awesome_calculator/shql/execution/lazy_child_execution_node.dart';
import 'package:awesome_calculator/shql/execution/artithmetic/multiplication_execution_node.dart';
import 'package:awesome_calculator/shql/execution/runtime.dart';
import 'package:awesome_calculator/shql/parser/parse_tree.dart';
import 'package:awesome_calculator/shql/tokenizer/token.dart';

class IdentifierExecutionNode extends LazyChildExecutionNode {
  IdentifierExecutionNode(super.node);

  @override
  ExecutionNode? createChildNode(Runtime runtime) {
    var identifier = node.qualifier!;
    var name = runtime.identifiers.constants[identifier];

    // A identifier can have 0 or 1 chhildren
    if (node.children.length > 1) {
      error =
          "Identifier $name can have at most one child, ${node.children.length} given.";
      return null;
    }

    // Try to resolve identifier (variables shadow constants, walks parent chain)
    var (value, isValue) = runtime.resolveIdentifier(identifier);
    var resolved = isValue;
    var userFunction = resolved ? null : runtime.getUserFunction(identifier);
    var nullaryFunction = resolved ? null : runtime.getNullaryFunction(name);
    resolved = resolved || nullaryFunction != null;
    var unaryFunction = resolved ? null : runtime.getUnaryFunction(identifier);
    resolved = resolved || unaryFunction != null;
    var binaryFunction = resolved
        ? null
        : runtime.getBinaryFunction(identifier);
    resolved = resolved || binaryFunction != null;

    // The child must be tuple or list if present
    if (node.children.length == 1) {
      var child = node.children[0];
      var childSymbol = child.symbol;

      if (childSymbol == Symbols.list) {
        return createIndexerExecutionNode(isValue, name, value, child.children);
      }

      if (childSymbol == Symbols.tuple) {
        return createFunctionCallExecutionNode(
          runtime,
          isValue,
          name,
          value,
          userFunction,
          nullaryFunction,
          unaryFunction,
          binaryFunction,
          child.children,
        );
      }

      error = "Identifier $name can only have a tuple or list as child.";
      return null;
    }

    if (isValue) {
      result = value;
      return null;
    }

    if (nullaryFunction != null &&
        binaryFunction == null &&
        unaryFunction == null &&
        userFunction == null) {
      return createFunctionCallExecutionNode(
        runtime,
        isValue,
        name,
        value,
        null,
        nullaryFunction,
        null,
        null,
        [],
      );
    }

    if (unaryFunction != null || binaryFunction != null) {
      error = "Missing arguments list to function $name().";
      return null;
    }

    if (userFunction != null) {
      return LambdaExpressionExecutionNode(name, userFunction);
    }

    error = '''Unidentified identifier "$name" used as a constant.

Hint: enclose strings in quotes, e.g.          name ~ "Batman"       rather than:     name ~ Batman

''';
    return null;
  }

  ExecutionNode? createFunctionCallExecutionNode(
    Runtime runtime,
    bool isValue,
    String name,
    value,
    UserFunction? userFunction,
    Function()? nullaryFunction,
    Function(dynamic p1)? unaryFunction,
    Function(dynamic p1, dynamic p2)? binaryFunction,
    List<ParseTree> arguments,
  ) {
    var argumentCount = arguments.length;
    if (isValue) {
      if (argumentCount != 1) {
        error =
            "Attempt to use value $name as a function: ($argumentCount) argument(s) given.";
        return null;
      }

      // Special case: treat identifier followed by single-element tuple as multiplication
      var lhs = Engine.createExecutionNode(arguments[0]);
      return MultiplicationExecutionNode(AprioriExecutionNode(value), lhs!);
    }

    if (userFunction != null) {
      if (argumentCount != userFunction.argumentIdentifiers.length) {
        error =
            "Function $name) takes ${userFunction.argumentIdentifiers.length} arguments, $argumentCount given.";
        return null;
      }

      var argumentNodes = <ExecutionNode>[];
      for (var argument in arguments) {
        argumentNodes.add(Engine.createExecutionNode(argument)!);
      }

      return UserFunctionExecutionNode(
        userFunction.argumentIdentifiers,
        argumentNodes,
        Engine.createExecutionNode(userFunction.body)!,
      );
    }

    if (nullaryFunction != null) {
      if (argumentCount != 0) {
        error = "Function $name() takes 0 arguments, $argumentCount given.";
        return null;
      }
      return NullaryLambdaExecutionNode(nullaryFunction);
    }

    if (unaryFunction != null) {
      if (node.children.length != 1) {
        var argumentCount = node.children.length;
        error = "Function $name() takes 1 argument, $argumentCount given.";
        return null;
      }
      return UnaryLambdaExecutionNode(
        unaryFunction,
        Engine.createExecutionNode(arguments[0])!,
      );
    }

    if (binaryFunction != null) {
      if (argumentCount != 2) {
        error = "Function $name() takes 2 arguments, $argumentCount given.";
        return null;
      }

      return BinaryLambdaExecutionNode(
        binaryFunction,
        Engine.createExecutionNode(arguments[0])!,
        Engine.createExecutionNode(arguments[1])!,
      );
    }
    error = 'Unidentified identifier "$name" used as a function.';
    return null;
  }

  IndexerExecutionNode? createIndexerExecutionNode(
    bool isValue,
    String identifier,
    value,
    List<ParseTree> indexes,
  ) {
    var argumentCount = indexes.length;
    if (isValue) {
      if (argumentCount != 1) {
        error =
            "Attempt to use value $identifier as a function: ($argumentCount) argument(s) given.";
        return null;
      }

      // Special case: treat identifier followed by single-element list as indexing
      var lhs = Engine.createExecutionNode(indexes[0]);
      return IndexerExecutionNode(AprioriExecutionNode(value), lhs!);
    }

    error = 'Identifier "$identifier" used with indexer.';
    return null;
  }
}
