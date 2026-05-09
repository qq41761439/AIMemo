import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'models/period_type.dart';
import 'models/summary_record.dart';
import 'models/task_record.dart';
import 'services/app_database.dart';
import 'services/in_memory_memo_store.dart';
import 'services/memo_store.dart';
import 'services/summary_api_client.dart';

final appDatabaseProvider = Provider<MemoStore>((ref) {
  final store = kIsWeb ? InMemoryMemoStore() : AppDatabase();
  ref.onDispose(() {
    store.close();
  });
  return store;
});

final summaryApiClientProvider = Provider<SummaryApiClient>((ref) {
  return SummaryApiClient();
});

final taskTagFilterProvider = StateProvider<Set<String>>((ref) => <String>{});

final selectedTaskProvider = StateProvider<TaskRecord?>((ref) => null);

final editingTaskProvider = StateProvider<TaskRecord?>((ref) => null);

final taskListProvider = FutureProvider<List<TaskRecord>>((ref) async {
  final database = ref.watch(appDatabaseProvider);
  final tags = ref.watch(taskTagFilterProvider);
  return database.listTasks(tagNames: tags.toList());
});

final tagListProvider = FutureProvider<List<String>>((ref) async {
  final database = ref.watch(appDatabaseProvider);
  return database.listTags();
});

final summaryHistoryProvider = FutureProvider<List<SummaryRecord>>((ref) async {
  final database = ref.watch(appDatabaseProvider);
  return database.listSummaries();
});

final templateProvider = FutureProvider.family<String, PeriodType>((ref, type) {
  final database = ref.watch(appDatabaseProvider);
  return database.getTemplate(type);
});
