import 'dart:async';
import 'dart:developer';

import 'package:bloc/bloc.dart';

import '../utils/utils.dart';
import 'resource_state.dart';

/// This can be both query and mutation since they return similar result.
typedef QueryExecutor<T> = Future<T> Function();

/// Parser must return expected result.
typedef ResultParser<T, R> = T Function(R result);

/// Function which will be invoked after successful mutation/query
typedef OnSuccessCallback<T> = FutureOr<void> Function(T result);
typedef OnExceptionCallback = void Function(Object exception);

/// This abstracts calling repository and handling result.
class ResourceCubit<T> extends Cubit<ResourceState<T>> {
  ResourceCubit() : super(const ResourceState());

  execute<R>({
    required QueryExecutor<R> executor,
    ResultParser<T, R>? parser,
    OnSuccessCallback<T>? onSuccess,
    OnExceptionCallback? onException,
  }) async {
    try {
      /// For showing loading
      emit(const ResourceState(status: ResourceStatus.loading));

      final result = await executor();
      final data = parser == null ? result as T : parser(result);

      if (onSuccess != null) {
        await onSuccess(data);
      }

      emit(ResourceState(status: ResourceStatus.success, data: data));
    } catch (e) {
      log('caught exception ${e.toString()}');
      final message = formatGraphqlError(e);

      if (onException != null) {
        onException(e);
      }

      emit(
        ResourceState(
          status: ResourceStatus.error,
          exception: e,
          errorMessage: message,
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
