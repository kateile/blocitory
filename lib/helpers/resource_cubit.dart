import 'dart:async';
import 'dart:developer';

import 'package:bloc/bloc.dart';
import 'package:graphql_flutter/graphql_flutter.dart';

import 'resource_state.dart';

/// This can be both query and mutation since they return similar result.
typedef QueryExecutor = Future<QueryResult> Function();

/// Parser must return expected result.
typedef ResultParser<T> = T Function(Map<String, dynamic> result);

/// Function which will be invoked after successful mutation/query
typedef OnSuccessCallback<T> = FutureOr<void> Function(T result);
typedef OnExceptionCallback = void Function(OperationException);

/// This abstracts calling repository and handling result.
class ResourceCubit<T> extends Cubit<ResourceState<T>> {
  ResourceCubit() : super(const ResourceState());

  execute({
    required QueryExecutor executor,
    required ResultParser<T> parser,
    OnSuccessCallback<T>? onSuccess,
    OnExceptionCallback? onException,
  }) async {
    try {
      /// For showing loading
      emit(
        const ResourceState(
          status: ResourceStatus.loading,
        ),
      );

      /// Invoke query/mutation
      final result = await executor();

      /// Handling result
      if (result.hasException) {
        /// for more direction
        if (onException != null) {
          /// This is useful in auth
          onException(result.exception!);
        }

        emit(
          ResourceState(
            status: ResourceStatus.error,
            exception: result.exception,
          ),
        );
      } else {
        /// Making sure types match
        final T data = parser(result.data!);

        if (onSuccess != null) {
          /// This is useful in auth
          await onSuccess(data);
        }

        emit(
          ResourceState(
            status: ResourceStatus.success,
            data: data,
          ),
        );
      }
    } catch (e) {
      log('caught exception ${e.toString()}');

      emit(
        ResourceState(
          status: ResourceStatus.error,
          exception: e,
        ),
      );
    }
  }

  /// This will update the previous fetched result
  update(T? newData) {
    if (newData != null) {
      emit(
        ResourceState(
          status: ResourceStatus.success,
          data: newData,
          updatedAt: DateTime.now().millisecondsSinceEpoch,
        ),
      );
    }
  }
}
