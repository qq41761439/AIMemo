enum PeriodType {
  daily('daily', '日报', '今天'),
  weekly('weekly', '周报', '本周'),
  monthly('monthly', '月报', '本月'),
  yearly('yearly', '年报', '今年'),
  custom('custom', '自定义', '自定义');

  const PeriodType(this.value, this.title, this.placeholderName);

  final String value;
  final String title;
  final String placeholderName;

  static PeriodType fromValue(String value) {
    return PeriodType.values.firstWhere(
      (type) => type.value == value,
      orElse: () => PeriodType.daily,
    );
  }
}
