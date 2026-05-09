import '../models/period_type.dart';

class PeriodRange {
  const PeriodRange({
    required this.start,
    required this.end,
    required this.label,
  });

  final DateTime start;
  final DateTime end;
  final String label;
}

PeriodRange periodRangeFor(PeriodType type, DateTime now) {
  final today = DateTime(now.year, now.month, now.day);

  switch (type) {
    case PeriodType.daily:
      final end = today.add(const Duration(days: 1));
      return PeriodRange(start: today, end: end, label: _ymd(today));
    case PeriodType.weekly:
      final start = today.subtract(Duration(days: today.weekday - 1));
      final end = start.add(const Duration(days: 7));
      return PeriodRange(
        start: start,
        end: end,
        label:
            '${_ymd(start)} 至 ${_ymd(end.subtract(const Duration(days: 1)))}',
      );
    case PeriodType.monthly:
      final start = DateTime(now.year, now.month);
      final end = DateTime(now.year, now.month + 1);
      return PeriodRange(
        start: start,
        end: end,
        label: '${now.year}年${_two(now.month)}月',
      );
    case PeriodType.yearly:
      final start = DateTime(now.year);
      final end = DateTime(now.year + 1);
      return PeriodRange(start: start, end: end, label: '${now.year}年');
  }
}

String compactDateTime(DateTime dateTime) {
  return '${_ymd(dateTime)} ${_two(dateTime.hour)}:${_two(dateTime.minute)}';
}

String compactDate(DateTime dateTime) => _ymd(dateTime);

String _ymd(DateTime dateTime) {
  return '${dateTime.year}-${_two(dateTime.month)}-${_two(dateTime.day)}';
}

String _two(int value) => value.toString().padLeft(2, '0');
