
class RepeatProtector {
  static final Set<dynamic> _errors = new Set<dynamic>();

  static bool shouldBeHandled(dynamic error) => _errors.add(error);
}
