import 'package:blocitory/blocitory.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('exports package entrypoints', () {
    expect(const ResourceState<int>().status, ResourceStatus.initial);
    expect(PagedState<int>().items, isEmpty);
  });
}
