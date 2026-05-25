import 'dart:async';

import 'package:bloc/bloc.dart';

import '../utils/error_formatter.dart';
import 'paged_state.dart';

typedef PagedQueryExecutor<R> = Future<List<R>> Function(int skip);

typedef PagedRefreshExecutor<R> = Future<List<R>> Function();

abstract class PagedCubit<R> extends Cubit<PagedState<R>> {
  final int _limit = 10;

  PagedCubit() : super(PagedState());

  void paginate({required PagedQueryExecutor<R> executor}) async {
    /// showing loading with other contents intact.
    emit(state.copyWith(status: PagedStatus.loading));

    if (state.status == PagedStatus.end) emit(state);

    /// This is inner function
    Future<List<R>> _fetch(int skip) => executor(skip);

    try {
      if (state.status == PagedStatus.initial) {
        final items = await _fetch(0);
        emit(
          state.copyWith(status: _hasReachedEnd(items.length), items: items),
        );
      }

      final items = await _fetch(state.items.length);

      if (items.isEmpty) {
        emit(state.copyWith(status: PagedStatus.end));
      } else {
        emit(
          state.copyWith(
            status: _hasReachedEnd(items.length),
            items: List.of(state.items)..addAll(items),
          ),
        );
      }
    } catch (e) {
      emit(
        state.copyWith(
          status: PagedStatus.failure,
          message: formatGraphqlError(e),
        ),
      );
    }
  }

  void handleRefresh({required PagedRefreshExecutor<R> executor}) async {
    final previousItems = state.items;

    /// showing is refreshing
    emit(state.copyWith(refreshStatus: RefreshStatus.refreshing));

    /// This is inner function
    Future<List<R>> _fetch() => executor();

    try {
      /// fetch from zero
      final items = await _fetch();

      /// Here we are not appending items we just set new ones.
      if (items.isEmpty) {
        emit(
          state.copyWith(
            status: PagedStatus.end,
            items: [],
            refreshStatus: RefreshStatus.success,
          ),
        );
      } else {
        emit(
          state.copyWith(
            status: _hasReachedEnd(items.length),
            items: items,
            refreshStatus: RefreshStatus.success,
          ),
        );
      }
    } catch (e) {
      //todo parse and format message.
      /// If there is error we just show previous items
      emit(
        state.copyWith(
          items: previousItems,
          refreshStatus: RefreshStatus.failure,
          message: e.toString(),
        ),
      );
    }
  }

  void addItems(List<R> newItems) async {
    final previousItems = state.items;

    emit(
      state.copyWith(
        items: [...newItems, ...previousItems],
        addedItems: newItems,
        updatedAt: DateTime.now().millisecondsSinceEpoch,
      ),
    );
  }

  void addItem(R newItem) async {
    emit(
      state.copyWith(
        items: [newItem, ...state.items],

        ///So that all items added will be shown as new
        addedItems: [newItem],
        updatedAt: DateTime.now().millisecondsSinceEpoch,
      ),
    );
  }

  /// Useful for deletable items eg contacts and requests
  void removeItem(R item) async {
    if (item != null) {
      final items = state.items;

      items.remove(item);

      emit(
        state.copyWith(
          items: items,
          updatedAt: DateTime.now().millisecondsSinceEpoch,
        ),
      );
    }
  }

  PagedStatus _hasReachedEnd(int itemsCount) =>
      itemsCount < _limit ? PagedStatus.end : PagedStatus.success;

  /// This is what is overridden and invoked to start and continue pagination
  fetch();

  refresh();
}
