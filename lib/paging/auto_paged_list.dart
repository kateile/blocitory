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
  final PagingController<int, T>? controller;

  const AutoPagedList({
    Key? key,
    required this.widgetBuilder,
    required this.executor,
    this.grid = false,
    this.crossAxisCount = 2,
    this.controller,
  }) : super(key: key);

  @override
  _AutoPagedListState createState() => _AutoPagedListState<T>();
}

class _AutoPagedListState<T> extends State<AutoPagedList<T>> {
  static const _pageSize = 10;

  late PagingController<int, T> _pagingController;

  @override
  void initState() {
    if (widget.controller != null) {
      _pagingController = widget.controller!;
    } else {
      _pagingController = PagingController(firstPageKey: 0);
    }
    _pagingController.addPageRequestListener((pageKey) {
      _fetchPage(pageKey);
    });
    super.initState();
  }

  Future<void> _fetchPage(int pageKey) async {
    try {
      final newData = await widget.executor(context, pageKey);

      final isLastPage = newData.length < _pageSize;
      if (isLastPage) {
        _pagingController.appendLastPage(newData);
      } else {
        final nextPageKey = pageKey + newData.length;
        _pagingController.appendPage(newData, nextPageKey);
      }
    } catch (error) {
      _pagingController.error = error;
    }
  }

  @override
  Widget build(BuildContext context) {
    return RefreshIndicator(
      onRefresh: () => Future.sync(() => _pagingController.refresh()),
      child: Builder(
        builder: (context) {
          if (widget.grid) {
            return PagedGridView<int, T>(
              gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: widget.crossAxisCount,
              ),
              pagingController: _pagingController,
              builderDelegate: PagedChildBuilderDelegate<T>(
                itemBuilder: (context, item, index) {
                  return widget.widgetBuilder(context, item);
                },
              ),
            );
          }

          return PagedListView<int, T>(
            pagingController: _pagingController,
            builderDelegate: PagedChildBuilderDelegate<T>(
              itemBuilder: (context, item, index) {
                return widget.widgetBuilder(context, item);
              },
            ),
          );
        },
      ),
    );
  }

  @override
  void dispose() {
    _pagingController.dispose();
    super.dispose();
  }
}
