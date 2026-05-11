import '../models/task_record.dart';

class TaskDraft {
  const TaskDraft({
    required this.title,
    required this.content,
  });

  final String title;
  final String content;
}

TaskDraft taskDraftFromBody(String value) {
  final cleanBody = value.trim();
  if (cleanBody.isEmpty) {
    throw ArgumentError('任务内容不能为空。');
  }

  final lines = cleanBody.split(RegExp(r'\r?\n'));
  final title = lines.first.trim();
  final content = lines.skip(1).join('\n').trim();
  return TaskDraft(title: title, content: content);
}

String taskBodyFromRecord(TaskRecord task) {
  final title = task.title.trim();
  final content = task.content.trim();
  if (content.isEmpty || content == title) {
    return title;
  }
  if (title.isEmpty) {
    return content;
  }
  return '$title\n$content';
}
