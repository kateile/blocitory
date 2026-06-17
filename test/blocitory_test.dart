import 'package:blocitory/blocitory.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('exports package entrypoints', () {
    expect(const ResourceState<int>().status, ResourceStatus.initial);
    expect(PagedState<int>().items, isEmpty);
  });

  test('formats GraphQL errors from exception graphqlErrors', () {
    final exception = _FakeGraphqlException([
      _FakeGraphqlError('account with similar email already exists'),
    ]);

    expect(
      formatGraphqlError(exception),
      'account with similar email already exists',
    );
  });

  test('formats GraphQL errors from parsed link response', () {
    final exception = _FakeLinkException([
      _FakeGraphqlError('account with similar email already exists'),
    ]);

    expect(
      formatGraphqlError(exception),
      'account with similar email already exists',
    );
  });

  test('formats decoded GraphQL error maps', () {
    final exception = _FakeGraphqlException([
      {'message': 'account with similar email already exists'},
    ]);

    expect(
      formatGraphqlError(exception),
      'account with similar email already exists',
    );
  });

  test('formats top-level GraphQL response errors when data is null', () {
    final response = {
      'errors': [
        {
          'message':
              'the requested element is null which the schema does not allow',
          'path': ['products', 2, 'account'],
        },
        {
          'message':
              'the requested element is null which the schema does not allow',
          'path': ['products', 0, 'account'],
        },
        {
          'message':
              'the requested element is null which the schema does not allow',
          'path': ['products', 1, 'account'],
        },
      ],
      'data': null,
    };

    expect(
      formatGraphqlError(response),
      'the requested element is null which the schema does not allow',
    );
  });

  test('operation exception extracts response graphql errors', () {
    final exception = GraphQLOperationException.fromResponse(
      operationName: 'signIn',
      response: _FakeGraphqlResponse(
        graphqlErrors: const [
          _FakeGraphqlError('incorrect username or password'),
        ],
      ),
    );

    expect(exception.message, 'incorrect username or password');
    expect(
      exception.graphqlErrors.single.message,
      'incorrect username or password',
    );
  });

  test('operation exception extracts top-level response errors', () {
    final exception = GraphQLOperationException.fromResponse(
      operationName: 'products',
      response: const _FakeGraphqlResponse(
        errors: [
          _FakeGraphqlError(
            'the requested element is null which the schema does not allow',
          ),
        ],
      ),
    );

    expect(
      exception.message,
      'the requested element is null which the schema does not allow',
    );
    expect(
      exception.graphqlErrors.single.message,
      'the requested element is null which the schema does not allow',
    );
  });

  test('operation exception sanitizes transport response errors', () {
    final exception = GraphQLOperationException.fromResponse(
      operationName: 'signIn',
      response: _FakeGraphqlResponse(
        linkException: const _FakeOriginalException(
          'DioException [connection error]: SocketException: '
          'address = 127.0.0.1, port = 52651, errno = 1225',
        ),
      ),
    );

    expect(exception.message, serverUnreachableMessage);
    expect(exception.message, isNot(contains('DioException')));
    expect(exception.message, isNot(contains('127.0.0.1')));
  });

  test('resource cubit emits error message when executor throws', () async {
    final cubit = ResourceCubit<String>();

    await cubit.execute(
      executor: () async => throw _FakeGraphqlException([
        _FakeGraphqlError('account with similar email already exists'),
      ]),
    );

    expect(cubit.state.status, ResourceStatus.error);
    expect(
      cubit.state.message,
      'account with similar email already exists',
    );

    await cubit.close();
  });

  test('resource state prefers stored error message', () {
    const state = ResourceState<String>(
      status: ResourceStatus.error,
      exception: 'raw exception',
      errorMessage: 'incorrect username or password',
    );

    expect(state.message, 'incorrect username or password');
  });

  test('formats transport failures as user-safe server errors', () {
    final message = formatGraphqlError(
      'DioException [connection error]: SocketException: '
      'address = 127.0.0.1, port = 52651, errno = 1225',
    );

    expect(message, 'Unable to connect to the server. Please try again later.');
    expect(message, isNot(contains('DioException')));
    expect(message, isNot(contains('127.0.0.1')));
    expect(message, isNot(contains('52651')));
  });

  testWidgets('mutation builder shows an inline error message', (tester) async {
    await tester.pumpWidget(
      RepositoryProvider<_FakeRepository>(
        create: (context) => const _FakeRepository(),
        child: MaterialApp(
          home: Scaffold(
            body: MutationBuilder<String, _FailingCubit, _FakeRepository>(
              blocCreator: (_) => _FailingCubit(),
              builder: (context, cubit) => TextButton(
                onPressed: cubit.fail,
                child: const Text('Sign in'),
              ),
            ),
          ),
        ),
      ),
    );

    await tester.tap(find.text('Sign in'));
    await tester.pumpAndSettle();

    expect(find.text('incorrect username or password'), findsWidgets);
  });
}

class _FakeGraphqlException {
  const _FakeGraphqlException(this.graphqlErrors);

  final List<dynamic> graphqlErrors;
}

class _FakeLinkException {
  _FakeLinkException(List<_FakeGraphqlError> errors)
    : linkException = _FakeLinkResponse(errors);

  final _FakeLinkResponse linkException;
}

class _FakeLinkResponse {
  _FakeLinkResponse(List<_FakeGraphqlError> errors)
    : parsedResponse = _FakeParsedResponse(errors);

  final _FakeParsedResponse parsedResponse;
}

class _FakeParsedResponse {
  const _FakeParsedResponse(this.errors);

  final List<_FakeGraphqlError> errors;
}

class _FakeGraphqlError {
  const _FakeGraphqlError(this.message);

  final String message;
}

class _FakeGraphqlResponse {
  const _FakeGraphqlResponse({
    this.errors,
    this.graphqlErrors,
    this.linkException,
  });

  final List<dynamic>? errors;
  final List<dynamic>? graphqlErrors;
  final Object? linkException;
}

class _FakeOriginalException {
  const _FakeOriginalException(this.originalException);

  final Object originalException;
}

class _FakeRepository {
  const _FakeRepository();
}

class _FailingCubit extends ResourceCubit<String> {
  void fail() {
    execute(
      executor: () async => throw _FakeGraphqlException([
        _FakeGraphqlError('incorrect username or password'),
      ]),
    );
  }
}
