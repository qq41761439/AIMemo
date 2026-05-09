import 'package:aimemo/src/models/period_type.dart';
import 'package:aimemo/src/services/period_utils.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('daily range covers local day', () {
    final range = periodRangeFor(PeriodType.daily, DateTime(2026, 5, 9, 15));

    expect(range.start, DateTime(2026, 5, 9));
    expect(range.end, DateTime(2026, 5, 10));
    expect(range.label, '2026-05-09');
  });

  test('weekly range starts on Monday', () {
    final range = periodRangeFor(PeriodType.weekly, DateTime(2026, 5, 9));

    expect(range.start, DateTime(2026, 5, 4));
    expect(range.end, DateTime(2026, 5, 11));
    expect(range.label, '2026-05-04 至 2026-05-10');
  });

  test('monthly range covers calendar month', () {
    final range = periodRangeFor(PeriodType.monthly, DateTime(2026, 12, 31));

    expect(range.start, DateTime(2026, 12));
    expect(range.end, DateTime(2027, 1));
    expect(range.label, '2026年12月');
  });

  test('yearly range covers calendar year', () {
    final range = periodRangeFor(PeriodType.yearly, DateTime(2026, 5, 9));

    expect(range.start, DateTime(2026));
    expect(range.end, DateTime(2027));
    expect(range.label, '2026年');
  });
}
