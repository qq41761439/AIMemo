import 'package:aimemo/src/models/task_record.dart';
import 'package:aimemo/src/services/task_body.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('splits one task body into title and details', () {
    final draft = taskDraftFromBody('整理发布清单\n确认 macOS 包和 README 更新');

    expect(draft.title, '整理发布清单');
    expect(draft.content, '确认 macOS 包和 README 更新');
  });

  test('uses single line task body as title only', () {
    final draft = taskDraftFromBody('整理发布清单');

    expect(draft.title, '整理发布清单');
    expect(draft.content, isEmpty);
  });

  test('combines stored title and content for editing', () {
    final task = TaskRecord(
      id: 1,
      title: '整理发布清单',
      content: '确认 macOS 包和 README 更新',
      tags: const [],
      createdAt: DateTime(2026, 5, 11),
    );

    expect(
      taskBodyFromRecord(task),
      '整理发布清单\n确认 macOS 包和 README 更新',
    );
  });
}
