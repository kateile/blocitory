import 'package:blocitory/blocitory.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:infinite_scroll_pagination/infinite_scroll_pagination.dart';

void main() {
  for (final grid in [false, true]) {
    testWidgets('loads offset pages and retries errors (grid: $grid)', (
      tester,
    ) async {
      final offsets = <int>[];
      var failNextPage = true;
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: AutoPagedList<int>(
              grid: grid,
              executor: (context, skip) async {
                offsets.add(skip);
                if (skip == 10 && failNextPage) {
                  throw Exception('Network unavailable');
                }
                if (skip == 0) return List.generate(10, (index) => index);
                return [10];
              },
              widgetBuilder: (context, item) =>
                  SizedBox(height: 80, child: Text('Item $item')),
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();
      await tester.drag(find.byType(Scrollable).first, const Offset(0, -1600));
      await tester.pumpAndSettle();
      final retry = find.text('Something went wrong. Tap to try again.');
      expect(retry, findsOneWidget);
      expect(tester.takeException(), isNull);
      failNextPage = false;
      await tester.ensureVisible(retry);
      await tester.pumpAndSettle();
      await tester.tap(retry);
      await tester.pumpAndSettle();
      expect(find.text('Item 10'), findsOneWidget);
      expect(offsets, [0, 10, 10]);
      await tester.drag(find.byType(Scrollable).first, const Offset(0, -1600));
      await tester.pumpAndSettle();
      expect(offsets, [0, 10, 10]);
    });
  }

  testWidgets('does not dispose a caller-owned controller', (tester) async {
    final controller = PagingController<int, int>(
      getNextPageKey: (_) => null,
      fetchPage: (_) async => [],
    );
    addTearDown(controller.dispose);
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: AutoPagedList<int>(
            controller: controller,
            executor: (_, _) async => [],
            widgetBuilder: (_, item) => Text('$item'),
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();
    await tester.pumpWidget(const SizedBox());
    expect(controller.refresh, returnsNormally);
  });
}
