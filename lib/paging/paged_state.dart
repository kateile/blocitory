import 'package:equatable/equatable.dart';

enum PagedStatus { initial, success, failure, loading, end }
enum RefreshStatus { initial, success, failure, refreshing }

class PagedState<T> extends Equatable {
  PagedState({
    this.status = PagedStatus.initial,
    this.message,
    this.refreshStatus = RefreshStatus.initial,
    List<T>? items,
    List<T>? addedItems,
    List<T>? updatedItems,
    this.updatedAt,
  })  : items = items ?? <T>[],
        newItems = addedItems ?? <T>[],
        updatedItems = updatedItems ?? <T>[];

  final PagedStatus status;
  final RefreshStatus refreshStatus;
  final List<T> items;

  /// New items from subscription/Mutation
  final List<T> newItems;

  /// When item is updated, it is also added in this list
  final List<T> updatedItems;
  final String? message;
  final int? updatedAt;

  PagedState<T> copyWith({
    PagedStatus? status,
    List<T>? items,
    String? message,
    RefreshStatus? refreshStatus,
    List<T>? addedItems,
    List<T>? updatedItems,
    int? updatedAt,
  }) {
    return PagedState(
      status: status ?? this.status,
      items: items ?? this.items,
      message: message,
      refreshStatus: refreshStatus ?? RefreshStatus.initial,
      addedItems: addedItems ?? newItems,
      updatedItems: updatedItems ?? this.updatedItems,
      updatedAt: updatedAt,
    );
  }

  @override
  List<Object?> get props => [
        status,
        items,
        message,
        refreshStatus,
        updatedItems,
        updatedAt,
        newItems,
      ];
}
