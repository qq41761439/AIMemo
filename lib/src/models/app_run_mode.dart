enum AppRunMode {
  local('local'),
  sync('sync');

  const AppRunMode(this.value);

  final String value;

  static AppRunMode? fromValue(String? value) {
    return AppRunMode.values.cast<AppRunMode?>().firstWhere(
          (mode) => mode?.value == value,
          orElse: () => null,
        );
  }
}
