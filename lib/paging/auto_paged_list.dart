import 'package:flutter/material.dart';
import 'package:infinite_scroll_pagination/infinite_scroll_pagination.dart';

typedef PagedListExecutor<T> =
    Future<List<T>> Function(BuildContext context, int skip);

typedef PagedListWidgetBuilder<T> =
    Widget Function(BuildContext context, T item);

class AutoPagedList<T> extends StatefulWidget {
  final PagedListWidgetBuilder<T> widgetBuilder;
  final PagedListExecutor<T> executor;
  final bool grid;
  final int crossAxisCount;

  /// An optional v6 controller. Its owner is responsible for disposing it.
  final PagingController<int, T>? controller;

  const AutoPagedList({
    super.key,
    required this.widgetBuilder,
    required this.executor,
    this.grid = false,
    this.crossAxisCount = 2,
    this.controller,
  });

  @override
  State<AutoPagedList<T>> createState() => _AutoPagedListState<T>();
}

class _AutoPagedListState<T> extends State<AutoPagedList<T>> {
  static const _pageSize = 10;
  late PagingController<int, T> _pagingController;
  late bool _ownsController;

  void _initializeController() {
    _ownsController = widget.controller == null;
    _pagingController =
        widget.controller ??
        PagingController<int, T>(
          getNextPageKey: (state) {
            if (state.pages.isEmpty) return 0;
            final lastPage = state.pages.last;
            if (lastPage.length < _pageSize) return null;
            return state.keys.last + lastPage.length;
          },
          fetchPage: (pageKey) => widget.executor(context, pageKey),
        );
  }

  @override
  void initState() {
    super.initState();
    _initializeController();
  }

  @override
  void didUpdateWidget(covariant AutoPagedList<T> oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.controller != widget.controller) {
      if (_ownsController) _pagingController.dispose();
      _initializeController();
    }
  }

  @override
  Widget build(BuildContext context) {
    return RefreshIndicator(
      onRefresh: () => Future.sync(_pagingController.refresh),
      child: PagingListener<int, T>(
        controller: _pagingController,
        builder: (context, state, fetchNextPage) {
          Widget retryIndicator(BuildContext context, Object error) => Padding(
            padding: const EdgeInsets.all(16),
            child: TextButton(
              onPressed: fetchNextPage,
              child: const Text('Something went wrong. Tap to try again.'),
            ),
          );
          // Keep indicators in Flutter Material, matching the host application.
          // Pagination v6 defaults use the separate material_ui widget library.
          final delegate = PagedChildBuilderDelegate<T>(
            firstPageErrorIndicatorBuilder: retryIndicator,
            newPageErrorIndicatorBuilder: retryIndicator,
            firstPageProgressIndicatorBuilder: (_) =>
                const Center(child: CircularProgressIndicator()),
            newPageProgressIndicatorBuilder: (_) =>
                const Center(child: CircularProgressIndicator()),
            noItemsFoundIndicatorBuilder: (_) =>
                const Center(child: Text('No items found')),
            itemBuilder: (context, item, index) =>
                widget.widgetBuilder(context, item),
          );
          if (widget.grid) {
            return PagedGridView<int, T>(
              gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: widget.crossAxisCount,
              ),
              state: state,
              fetchNextPage: fetchNextPage,
              builderDelegate: delegate,
            );
          }
          return PagedListView<int, T>(
            state: state,
            fetchNextPage: fetchNextPage,
            builderDelegate: delegate,
          );
        },
      ),
    );
  }

  @override
  void dispose() {
    if (_ownsController) _pagingController.dispose();
    super.dispose();
  }
}
