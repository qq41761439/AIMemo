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
    case PeriodType.custom:
      final end = today.add(const Duration(days: 1));
      return PeriodRange(start: today, end: end, label: _ymd(today));
  }
}

String compactDateTime(DateTime dateTime) {
  return '${_ymd(dateTime)} ${_two(dateTime.hour)}:${_two(dateTime.minute)}';
}

String compactDate(DateTime dateTime) => _ymd(dateTime);

String dateRangeLabel(DateTime start, DateTime exclusiveEnd) {
  final inclusiveEnd = exclusiveEnd.subtract(const Duration(days: 1));
  if (start.year == inclusiveEnd.year &&
      start.month == inclusiveEnd.month &&
      start.day == inclusiveEnd.day) {
    return _ymd(start);
  }
  return '${_ymd(start)} 至 ${_ymd(inclusiveEnd)}';
}

String _ymd(DateTime dateTime) {
  return '${dateTime.year}-${_two(dateTime.month)}-${_two(dateTime.day)}';
}

String _two(int value) => value.toString().padLeft(2, '0');
