import 'package:aimemo/src/app.dart';
import 'package:aimemo/src/providers.dart';
import 'package:aimemo/src/services/app_database.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';

void main() {
  testWidgets('AIMemo home renders primary panes', (tester) async {
    sqfliteFfiInit();
    databaseFactory = databaseFactoryFfi;
    final database = AppDatabase(pathOverride: inMemoryDatabasePath);
    addTearDown(database.close);

    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          appDatabaseProvider.overrideWithValue(database),
        ],
        child: const AIMemoApp(),
      ),
    );
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 250));

    expect(find.text('AIMemo'), findsOneWidget);
    expect(find.text('标签'), findsWidgets);
    expect(find.text('添加任务'), findsWidgets);
  });
}
