class RepeatProtector {
  static const int maxBufferSize = 1000;
  static final Set<dynamic> _errors = new Set<dynamic>();

  static bool shouldBeHandled(dynamic error) {
    if (_errors.length > maxBufferSize) {
      _errors.clear();
    }
    return _errors.add(error);
  }
}
