import 'logging_speed.dart';
import 'src/clock.dart';

class InfiniteLoopProtector {
  static final LoggingSpeed defaultMaxAllowedLoggingSpeed = new LoggingSpeed();
  final List<int> _timeRecords = [];
  bool _isProtectionEnabled = false;

  final Clock _clock;
  final LoggingSpeed _maxSpeed;

  InfiniteLoopProtector(
      {LoggingSpeed maxAllowedLoggingSpeed,
      @deprecated Clock clock: const Clock() /*For internal use only*/,
      @deprecated int maxAllowedSpeedPerMinute,
      @deprecated int speedControlInterval,
      @deprecated int totalMaxCount,
      @deprecated Duration protectionDuration})
      : this._maxSpeed = maxAllowedLoggingSpeed ?? defaultMaxAllowedLoggingSpeed,
        // ignore: deprecated_member_use
        this._clock = clock;

  bool call(dynamic event) {
    if (_isProtectionEnabled) {
      if (_clock.getNow().millisecondsSinceEpoch - _timeRecords.first > _maxSpeed.timeInterval.inMilliseconds) {
        _isProtectionEnabled = false;
        _timeRecords.clear();
      } else {
        return false;
      }
    }

    _timeRecords.add(_clock.getNow().millisecondsSinceEpoch);

    if (_timeRecords.length == _maxSpeed.eventsCount) {
      if (_timeRecords.last - _timeRecords.first < _maxSpeed.timeInterval.inMilliseconds) {
        _isProtectionEnabled = true;
      } else {
        _timeRecords.clear();
      }
    }

    return true;
  }
}
