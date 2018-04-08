class LoggingSpeed {
  static const Duration defaultTimeInterval = const Duration(seconds: 30);
  static const int defaultEventsCount = 10;
  final Duration timeInterval;
  final int eventsCount;

  LoggingSpeed({this.timeInterval: defaultTimeInterval, this.eventsCount: defaultEventsCount}) {
    if (timeInterval == Duration.ZERO && timeInterval.isNegative) {
      throw new ArgumentError.value(
        timeInterval,
        'timeInterval',
        'the value must be greater than zero',
      );
    }
    if (eventsCount <= 0) {
      throw new ArgumentError.value(
        eventsCount,
        'eventsCount',
        'the value must be greater than zero',
      );
    }
  }
}
