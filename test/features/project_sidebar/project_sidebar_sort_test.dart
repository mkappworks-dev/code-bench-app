import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:code_bench_app/features/project_sidebar/notifiers/project_sidebar_notifier.dart';

void main() {
  setUp(() {
    SharedPreferences.setMockInitialValues({});
  });

  test('default sort orders are lastMessage', () async {
    final container = ProviderContainer();
    addTearDown(container.dispose);
    final state = await container.read(projectSortProvider.future);
    expect(state.projectSort, ProjectSortOrder.lastMessage);
    expect(state.threadSort, ThreadSortOrder.lastMessage);
  });

  test('setProjectSort persists to SharedPreferences', () async {
    final container = ProviderContainer();
    addTearDown(container.dispose);
    await container.read(projectSortProvider.notifier).setProjectSort(ProjectSortOrder.createdAt);
    final prefs = await SharedPreferences.getInstance();
    expect(prefs.getString('project_sort_order'), 'createdAt');
  });

  test('setThreadSort updates state', () async {
    final container = ProviderContainer();
    addTearDown(container.dispose);
    await container.read(projectSortProvider.notifier).setThreadSort(ThreadSortOrder.createdAt);
    final state = await container.read(projectSortProvider.future);
    expect(state.threadSort, ThreadSortOrder.createdAt);
  });
}
