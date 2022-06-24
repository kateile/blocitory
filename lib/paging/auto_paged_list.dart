import 'package:flutter/material.dart';
import 'package:graphql_flutter/graphql_flutter.dart';
import 'package:infinite_scroll_pagination/infinite_scroll_pagination.dart';

typedef PagedListExecutor = Future<QueryResult> Function(
    BuildContext context, int skip);

/// Parser must return expected result.
typedef PagedListResultParser<R> = List<R> Function(QueryResult result);

typedef PagedListWidgetBuilder<T> = Widget Function(
    BuildContext context, T item);

class AutoPagedList<T> extends StatefulWidget {
  final PagedListWidgetBuilder<T> widgetBuilder;
  final PagedListExecutor executor; //executor
  final PagedListResultParser<T> parser;
  final bool grid;
  final int crossAxisCount;

  const AutoPagedList({
    Key? key,
    required this.widgetBuilder,
    required this.executor,
    required this.parser,
    this.grid = false,
    this.crossAxisCount = 2,
  }) : super(key: key);

  @override
  _AutoPagedListState createState() => _AutoPagedListState<T>();
}

class _AutoPagedListState<T> extends State<AutoPagedList<T>> {
  static const _pageSize = 10;

  final PagingController<int, T> _pagingController =
      PagingController(firstPageKey: 0);

  @override
  void initState() {
    _pagingController.addPageRequestListener((pageKey) {
      _fetchPage(pageKey);
    });
    super.initState();
  }

  Future<void> _fetchPage(int pageKey) async {
    try {
      final result = await widget.executor(context, pageKey);

      if (result.hasException) {
        print('Paging exception: ${result.exception}');
        _pagingController.error = result.exception;
      } else {
        final List<T> newData = widget.parser(result);

        final isLastPage = newData.length < _pageSize;
        if (isLastPage) {
          _pagingController.appendLastPage(newData);
        } else {
          final nextPageKey = pageKey + newData.length;
          print('nextPageKey: $nextPageKey');
          _pagingController.appendPage(newData, nextPageKey);
        }
      }
    } catch (error) {
      print('Paging exception: $error');
      _pagingController.error = error;
    }
  }

  @override
  Widget build(BuildContext context) {
    //todo is it working?
    return RefreshIndicator(
      onRefresh: () => Future.sync(
        () => _pagingController.refresh(),
      ),
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
