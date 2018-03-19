import 'dart:async';

class InfiniteLoopProtector {
  final List<int> _recordTimes = [];
  int _totalEventsCount = 0;
  bool _isProtectionEnabled = false;

  final int _speedControlInterval;
  final int _maxAllowedSpeed;
  final int _totalMaxCount;
  final Duration _protectionDuration;

  InfiniteLoopProtector(
      {int speedControlInterval: 10,
      int maxAllowedSpeedPerMinute: 10,
      int totalMaxCount: 100,
      Duration protectionDuration: const Duration(seconds: 5)})
      : this._speedControlInterval = speedControlInterval,
        this._maxAllowedSpeed = maxAllowedSpeedPerMinute,
        this._totalMaxCount = totalMaxCount,
        this._protectionDuration = protectionDuration;

  bool call(dynamic event) {
    _totalEventsCount++;
    _recordTimes.add(new DateTime.now().millisecondsSinceEpoch);

    if (_isProtectionEnabled) {
      return false;
    }

    if (_shouldBeProtectedByMaxCount()) {
      _isProtectionEnabled = true;

      return false;
    }

    if (_isInsideOfControl() && _shouldBeProtectedBySpeed()) {
      _isProtectionEnabled = true;
      _recordTimes.clear();

      new Future<Null>.delayed(_protectionDuration).then((_) {
        _isProtectionEnabled = false;
      });

      return false;
    }

    return true;
  }

  //TODO: update constant value after the Dart 2.0 release
  double _getSpeed() =>
      _recordTimes.length / ((_recordTimes.last - _recordTimes.first) / 60000 /*Duration.MILLISECONDS_PER_MINUTE)*/);

  bool _isInsideOfControl() => _speedControlInterval <= 0 || _recordTimes.length > _speedControlInterval;

  bool _shouldBeProtectedByMaxCount() => _totalMaxCount > 0 && _totalEventsCount > _totalMaxCount;

  bool _shouldBeProtectedBySpeed() => _maxAllowedSpeed > 0 && _getSpeed() > _maxAllowedSpeed;
}
