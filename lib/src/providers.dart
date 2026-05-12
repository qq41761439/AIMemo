import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'models/app_run_mode.dart';
import 'models/model_settings.dart';
import 'models/period_type.dart';
import 'models/summary_record.dart';
import 'models/task_record.dart';
import 'services/app_database.dart';
import 'services/in_memory_memo_store.dart';
import 'services/memo_store.dart';
import 'services/model_settings_repository.dart';
import 'services/summary_api_client.dart';
import 'services/sync_api_client.dart';
import 'services/sync_coordinator.dart';

final appDatabaseProvider = Provider<MemoStore>((ref) {
  final store = kIsWeb ? InMemoryMemoStore() : AppDatabase();
  ref.onDispose(() {
    store.close();
  });
  return store;
});

final summaryApiClientProvider = Provider<SummaryApiClient>((ref) {
  final repository = ref.watch(modelSettingsRepositoryProvider);
  return SummaryApiClient(
    refreshHostedConfig: repository.refreshHostedConfig,
  );
});

final apiKeyVaultProvider = Provider<ApiKeyVault>((ref) {
  return const SecureApiKeyVault();
});

final modelSettingsRepositoryProvider =
    Provider<ModelSettingsRepository>((ref) {
  return ModelSettingsRepository(
    store: ref.watch(appDatabaseProvider),
    apiKeyVault: ref.watch(apiKeyVaultProvider),
  );
});

final modelSettingsProvider = FutureProvider((ref) {
  return ref.watch(modelSettingsRepositoryProvider).load();
});

final hostedQuotaProvider = FutureProvider<HostedQuota?>((ref) async {
  final settings = await ref.watch(modelSettingsProvider.future);
  if (settings.mode != ModelMode.hosted || !settings.hasHostedSession) {
    return null;
  }
  return ref.watch(modelSettingsRepositoryProvider).loadHostedQuota();
});

final appRunModeProvider = FutureProvider<AppRunMode?>((ref) async {
  final repository = ref.watch(modelSettingsRepositoryProvider);
  final settings = await repository.load();
  if (settings.hasHostedSession) {
    return AppRunMode.sync;
  }
  final mode = await repository.loadAppRunMode();
  return mode == AppRunMode.local ? AppRunMode.local : null;
});

final syncConfigProvider = FutureProvider<SyncConfig?>((ref) {
  return ref.watch(modelSettingsRepositoryProvider).loadSyncConfig();
});

final syncApiClientProvider = FutureProvider<SyncApiClient?>((ref) async {
  final config = await ref.watch(syncConfigProvider.future);
  if (config == null) {
    return null;
  }
  final repository = ref.watch(modelSettingsRepositoryProvider);
  return SyncApiClient(
    config: config,
    refreshConfig: repository.refreshSyncConfig,
  );
});

final syncCoordinatorProvider = FutureProvider<SyncCoordinator?>((ref) async {
  final client = await ref.watch(syncApiClientProvider.future);
  final store = ref.watch(appDatabaseProvider);
  if (client == null || store is! AppDatabase) {
    return null;
  }
  return SyncCoordinator(database: store, client: client);
});

final taskTagFilterProvider = StateProvider<Set<String>>((ref) => <String>{});

final selectedTaskProvider = StateProvider<TaskRecord?>((ref) => null);

final editingTaskProvider = StateProvider<TaskRecord?>((ref) => null);

final taskPaneFocusRequestProvider = StateProvider<int>((ref) => 0);

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

final hostedSummaryHistoryProvider =
    FutureProvider<List<HostedSummaryRecord>>((ref) async {
  final settings = await ref.watch(modelSettingsProvider.future);
  if (settings.mode != ModelMode.hosted || !settings.hasHostedSession) {
    return const [];
  }
  return ref.watch(modelSettingsRepositoryProvider).listHostedSummaries();
});

final templateProvider = FutureProvider.family<String, PeriodType>((ref, type) {
  final database = ref.watch(appDatabaseProvider);
  return database.getTemplate(type);
});
