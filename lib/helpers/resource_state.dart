import 'package:equatable/equatable.dart';

import '../utils/utils.dart';

enum ResourceStatus { initial, success, error, loading }

class ResourceState<T> extends Equatable {
  const ResourceState({
    this.status = ResourceStatus.initial,
    this.data,
    this.exception,
    this.updatedAt,
  });

  final ResourceStatus status;
  final T? data;
  final dynamic exception;

  ///Useful for updating new state since change in just T is not enough
  final int? updatedAt;

  String? get message {
    return formatGraphqlError(exception);
  }

  @override
  List<Object?> get props => [status, data, exception, updatedAt];
}
