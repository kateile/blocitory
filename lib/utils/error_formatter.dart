import 'dart:developer';

const serverUnreachableMessage =
    'Unable to connect to the server. Please try again later.';

String? formatGraphqlError(dynamic exception) {
  if (exception == null) return null;

  log('result exception ${exception.toString()}');

  final messages = <String>[
    ..._messagesFromErrors(_property(exception, 'errors')),
    ..._messagesFromErrors(_property(exception, 'graphqlErrors')),
    ..._messagesFromErrors(
      _property(
        _property(exception, 'linkException'),
        'parsedResponse',
      )?.errors,
    ),
    ..._messagesFromErrors(_property(exception, 'parsedResponse')?.errors),
    ..._messagesFromErrors(_property(exception, 'response')?.errors),
  ];

  final message = _joinMessages(messages);
  if (message != null) return message;

  if (_isConnectionFailure(exception)) return serverUnreachableMessage;

  try {
    final String message = exception.message;
    if (_isConnectionFailure(message)) return serverUnreachableMessage;
    if (message.trim().isNotEmpty) return message.trim();
  } catch (_) {}

  log('Error to be formatter exception: ${exception.toString()}');
  //If we can't extract messages above then it could be internet error.
  return 'Please make sure your internet connection is working properly.';
}

class GraphQLOperationException implements Exception {
  const GraphQLOperationException({
    required this.operationName,
    required this.message,
    this.graphqlErrors = const [],
    this.linkException,
  });

  factory GraphQLOperationException.fromResponse({
    required String operationName,
    required dynamic response,
  }) {
    final linkException = _property(response, 'linkException');
    final graphqlErrors = _uniqueMessages([
      ..._messagesFromErrors(_property(response, 'errors')),
      ..._messagesFromErrors(_property(response, 'graphqlErrors')),
      ..._messagesFromErrors(_property(response, 'parsedResponse')?.errors),
      ..._messagesFromErrors(
        _property(_property(linkException, 'parsedResponse'), 'errors'),
      ),
    ]).map(GraphQLErrorMessage.new).toList();

    final message = [
      if (graphqlErrors.isNotEmpty)
        graphqlErrors.map((error) => error.message).join('\n'),
      if (graphqlErrors.isEmpty && linkException != null)
        graphqlOperationMessage(linkException),
    ].where((part) => part.isNotEmpty).join('\n');

    return GraphQLOperationException(
      operationName: operationName,
      message: message.isEmpty ? 'GraphQL operation failed.' : message,
      graphqlErrors: graphqlErrors,
      linkException: linkException,
    );
  }

  factory GraphQLOperationException.fromException({
    required String operationName,
    required Object exception,
  }) {
    return GraphQLOperationException(
      operationName: operationName,
      message: graphqlOperationMessage(exception),
      linkException: exception,
    );
  }

  final String operationName;
  final String message;
  final List<GraphQLErrorMessage> graphqlErrors;
  final Object? linkException;

  @override
  String toString() => 'GraphQLOperationException($operationName): $message';
}

class GraphQLMutationException extends GraphQLOperationException {
  const GraphQLMutationException({
    required super.operationName,
    required super.message,
    super.graphqlErrors = const [],
    super.linkException,
  });

  factory GraphQLMutationException.fromResponse({
    required String operationName,
    required dynamic response,
  }) {
    final operationException = GraphQLOperationException.fromResponse(
      operationName: operationName,
      response: response,
    );

    return GraphQLMutationException(
      operationName: operationException.operationName,
      message: operationException.message.isEmpty
          ? 'GraphQL mutation failed.'
          : operationException.message,
      graphqlErrors: operationException.graphqlErrors,
      linkException: operationException.linkException,
    );
  }
}

class GraphQLErrorMessage {
  const GraphQLErrorMessage(this.message);

  final String message;
}

String graphqlOperationMessage(Object exception) {
  final parsedMessages = _uniqueMessages([
    ..._messagesFromErrors(_property(exception, 'errors')),
    ..._messagesFromErrors(
      _property(_property(exception, 'parsedResponse'), 'errors'),
    ),
  ]);
  if (parsedMessages.isNotEmpty) return parsedMessages.join('\n');

  if (_isConnectionFailure(exception)) return serverUnreachableMessage;

  final originalException = _property(exception, 'originalException');
  if (originalException != null) {
    if (_isConnectionFailure(originalException)) {
      return serverUnreachableMessage;
    }

    final message = originalException.toString().trim();
    if (message.isNotEmpty) return message;
  }

  final message = exception.toString().trim();
  return message.isEmpty ? 'GraphQL operation failed.' : message;
}

Iterable<String> _messagesFromErrors(dynamic errors) {
  if (errors is! Iterable) return const <String>[];

  return errors
      .map(_extractMessage)
      .whereType<String>()
      .where((message) => message.isNotEmpty);
}

dynamic _property(dynamic object, String name) {
  if (object == null) return null;

  try {
    switch (name) {
      case 'errors':
        return object.errors;
      case 'graphqlErrors':
        return object.graphqlErrors;
      case 'linkException':
        return object.linkException;
      case 'originalException':
        return object.originalException;
      case 'parsedResponse':
        return object.parsedResponse;
      case 'response':
        return object.response;
    }
  } catch (_) {}

  if (object is Map) return object[name];

  return null;
}

String? _extractMessage(dynamic error) {
  try {
    final String message = error.message;
    if (message.trim().isNotEmpty) return message.trim();
  } catch (_) {}

  if (error is Map && error['message'] is String) {
    final message = (error['message'] as String).trim();
    if (message.isNotEmpty) return message;
  }

  if (error is String && error.trim().isNotEmpty) return error.trim();

  return null;
}

List<String> _uniqueMessages(Iterable<String> messages) {
  final uniqueMessages = <String>[];
  for (final message in messages) {
    if (!uniqueMessages.contains(message)) {
      uniqueMessages.add(message);
    }
  }

  return uniqueMessages;
}

String? _joinMessages(Iterable<String> messages) {
  final uniqueMessages = _uniqueMessages(messages);
  if (uniqueMessages.isEmpty) return null;

  return uniqueMessages.join('\n');
}

bool _isConnectionFailure(Object exception) {
  final text = exception.toString().toLowerCase();
  return text.contains('connection error') ||
      text.contains('connection refused') ||
      text.contains('socketexception') ||
      text.contains('failed host lookup') ||
      text.contains('network is unreachable') ||
      text.contains('connection timed out') ||
      text.contains('connection timeout') ||
      text.contains('errno = 1225');
}
