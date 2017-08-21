class LoggingEnvironment {
  static const LoggingEnvironment local = const LoggingEnvironment._('local');
  static const LoggingEnvironment remote = const LoggingEnvironment._('remote');

  final String value;

  const LoggingEnvironment._(this.value);

  String toJson() => value;

  @override
  String toString() => 'LoggingEnvironment:$value';
}
