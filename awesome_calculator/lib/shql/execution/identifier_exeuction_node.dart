import 'package:awesome_calculator/shql/engine/cancellation_token.dart';
import 'package:awesome_calculator/shql/engine/engine.dart';
import 'package:awesome_calculator/shql/execution/execution_node.dart';
import 'package:awesome_calculator/shql/execution/index_to_execution_node.dart';
import 'package:awesome_calculator/shql/execution/lambdas/binary_lambda_execution_node.dart';
import 'package:awesome_calculator/shql/execution/lambdas/lambda_expression_execution_node.dart';
import 'package:awesome_calculator/shql/execution/lambdas/nullary_lambda_execution_node.dart';
import 'package:awesome_calculator/shql/execution/lambdas/unary_lambda_execution_node.dart';
import 'package:awesome_calculator/shql/execution/lambdas/user_function_execution_node.dart';
import 'package:awesome_calculator/shql/execution/lazy_execution_node.dart';
import 'package:awesome_calculator/shql/execution/operators/artithmetic/multiply_with_execution_node.dart';
import 'package:awesome_calculator/shql/execution/runtime.dart';
import 'package:awesome_calculator/shql/parser/parse_tree.dart';
import 'package:awesome_calculator/shql/tokenizer/token.dart';

class IdentifierExecutionNode extends LazyExecutionNode {
  IdentifierExecutionNode(
    super.node, {
    required super.thread,
    required super.scope,
  });

  ExecutionNode? _childNode;

  @override
  Future<TickResult> doTick(
    Runtime runtime,
    CancellationToken? cancellationToken,
  ) async {
    if (_childNode == null) {
      var (childNode, value, error) = createChildNode(runtime);
      if (error != null) {
        this.error = error;
        return TickResult.completed;
      }
      if (childNode == null) {
        result = value;
        return TickResult.completed;
      }
      _childNode = childNode;
      return TickResult.delegated;
    }

    result = _childNode!.result;
    error ??= _childNode!.error;
    return TickResult.completed;
  }

  (ExecutionNode?, dynamic, String?) createChildNode(Runtime runtime) {
    var identifier = node.qualifier!;
    var name = runtime.identifiers.constants[identifier];

    // A identifier can have 0 or 1 chhildren
    if (node.children.length > 1) {
      return (
        null,
        null,
        "Identifier $name can have at most one child, ${node.children.length} given.",
      );
    }

    // Try to resolve identifier (variables shadow constants, walks parent chain)
    var (value, containingScope, isConstant) = scope.resolveIdentifier(
      identifier,
    );
    var resolved = containingScope != null;
    var isUserFunction = resolved && value is UserFunction;
    UserFunction? userFunction = isUserFunction ? value as UserFunction? : null;
    var isVariable = resolved && !isUserFunction && !isConstant;
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
        return createIndexToExecutionNode(
          runtime,
          isVariable,
          name,
          value,
          child.children,
        );
      }

      if (childSymbol == Symbols.tuple) {
        return createFunctionCallExecutionNode(
          runtime,
          isVariable,
          isConstant,
          name,
          value,
          userFunction,
          nullaryFunction,
          unaryFunction,
          binaryFunction,
          child.children,
        );
      }

      return (
        null,
        null,
        "Identifier $name can only have a tuple or list as child.",
      );
    }

    if (isVariable || isConstant) {
      return (null, value, null);
    }

    if (nullaryFunction != null &&
        binaryFunction == null &&
        unaryFunction == null &&
        userFunction == null) {
      return createFunctionCallExecutionNode(
        runtime,
        isVariable,
        isConstant,
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
      return (null, null, "Missing arguments list to function $name().");
    }

    if (userFunction != null) {
      return (
        LambdaExpressionExecutionNode.alias(
          name,
          node,
          userFunction,
          thread: thread,
          scope: scope,
        ),
        null,
        null,
      );
    }

    return (
      null,
      null,
      '''Unidentified identifier "$name" used as a constant.

Hint: enclose strings in quotes, e.g.          name ~ "Batman"       rather than:     name ~ Batman

''',
    );
  }

  (ExecutionNode?, dynamic, String?) createFunctionCallExecutionNode(
    Runtime runtime,
    bool isVariable,
    bool isConstant,
    String name,
    value,
    UserFunction? userFunction,
    Function()? nullaryFunction,
    Function(dynamic p1)? unaryFunction,
    Function(dynamic p1, dynamic p2)? binaryFunction,
    List<ParseTree> arguments,
  ) {
    var argumentCount = arguments.length;
    if (isVariable || isConstant) {
      if (argumentCount != 1) {
        return (
          null,
          null,
          "Attempt to use ${isConstant ? "constant" : "variable"} $name as a function: ($argumentCount) argument(s) given.",
        );
      }

      // Special case: treat identifier followed by single-element tuple as multiplication
      return (
        MultiplyWithExecutionNode(
          arguments[0],
          value,
          thread: thread,
          scope: scope,
        ),
        null,
        null,
      );
    }

    if (userFunction != null) {
      if (argumentCount != userFunction.argumentIdentifiers.length) {
        return (
          null,
          null,
          "Function $name) takes ${userFunction.argumentIdentifiers.length} arguments, $argumentCount given.",
        );
      }

      return (
        UserFunctionExecutionNode(
          userFunction,
          arguments,
          thread: thread,
          scope: scope,
        ),
        null,
        null,
      );
    }

    if (nullaryFunction != null) {
      if (argumentCount != 0) {
        return (
          null,
          null,
          "Function $name() takes 0 arguments, $argumentCount given.",
        );
      }
      return (
        NullaryLambdaExecutionNode(
          nullaryFunction,
          thread: thread,
          scope: scope,
        ),
        null,
        null,
      );
    }

    if (unaryFunction != null) {
      if (node.children.length != 1) {
        var argumentCount = node.children.length;
        return (
          null,
          null,
          "Function $name() takes 1 argument, $argumentCount given.",
        );
      }
      return (
        UnaryLambdaExecutionNode(
          unaryFunction,
          arguments[0],
          thread: thread,
          scope: scope,
        ),
        null,
        null,
      );
    }

    if (binaryFunction != null) {
      if (argumentCount != 2) {
        return (
          null,
          null,
          "Function $name() takes 2 arguments, $argumentCount given.",
        );
      }

      return (
        BinaryLambdaExecutionNode(
          binaryFunction,
          arguments[0],
          arguments[1],
          thread: thread,
          scope: scope,
        ),
        null,
        null,
      );
    }
    return (null, null, 'Unidentified identifier "$name" used as a function.');
  }

  (IndexToExecutionNode?, dynamic, String?) createIndexToExecutionNode(
    Runtime runtime,
    bool isValue,
    String identifier,
    index,
    List<ParseTree> indexes,
  ) {
    var argumentCount = indexes.length;
    if (isValue) {
      if (argumentCount != 1) {
        return (
          null,
          null,
          "Attempt to use value $identifier as a function: ($argumentCount) argument(s) given.",
        );
      }

      // Special case: treat identifier followed by single-element list as indexing
      return (
        IndexToExecutionNode(indexes[0], index, thread: thread, scope: scope),
        null,
        null,
      );
    }

    return (null, null, 'Identifier "$identifier" used with indexer.');
  }
}
