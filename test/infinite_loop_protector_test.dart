@TestOn('browser')
import 'package:logging_service/infinite_loop_protector.dart';
import 'package:logging_service/logging_speed.dart';
import 'package:logging_service/src/clock.dart';
import 'package:mockito/mockito.dart';
import 'package:test/test.dart';

void main() {
  group('The protector should', () {
    final stepInterval = LoggingSpeed.defaultTimeInterval + new Duration(seconds: 1);

    setUp(() {});

    test('return false if the speed of incoming events is more than allowed', () {
      var protector = new InfiniteLoopProtector();
      var events = new List.generate(LoggingSpeed.defaultEventsCount + 1, (_) => new Object());

      var results = events.map((dynamic event) => protector(event)).toList();

      expect(results.last, false);
    });

    test('return true for all events while the speed is allowed', () {
      var start = new DateTime.now();
      var clockMock = new ClockMock();
      when(clockMock.getNow()).thenReturn(start);
      // ignore: deprecated_member_use
      var protector = new InfiniteLoopProtector(clock: clockMock);
      var events = new List.generate(LoggingSpeed.defaultEventsCount, (_) => new Object());

      var results = events.map((dynamic event) => protector(event)).toList();
      when(clockMock.getNow()).thenReturn(start.add(stepInterval));
      results.add(protector(new Object()));

      expect(results.reduce((value, current) => value && current), true);
    });

    test('be able to switch betwen modes', () {
      var start = new DateTime.now();
      var clockMock = new ClockMock();
      when(clockMock.getNow()).thenReturn(start);
      // ignore: deprecated_member_use
      var protector = new InfiniteLoopProtector(clock: clockMock);
      var events = new List.generate(LoggingSpeed.defaultEventsCount, (_) => new Object());

      events.forEach((dynamic event) => protector(event));
      var resultInProtectionMode =
          events.map((dynamic event) => protector(event)).reduce((value, current) => value && current);

      when(clockMock.getNow()).thenReturn(start.add(stepInterval));
      var resultInAllowingMode =
          events.map((dynamic event) => protector(event)).reduce((value, current) => value && current);

      when(clockMock.getNow()).thenReturn(start.add(stepInterval * 2));
      var resultInAllowingMode2 =
          events.map((dynamic event) => protector(event)).reduce((value, current) => value && current);

      var resultInProtectionMode2 = protector(new Object());

      expect(resultInProtectionMode, false,
          reason: 'The protector did not switch to the protection mode at the first time');
      expect(resultInAllowingMode, true,
          reason: 'The protector did not switched back to the allowing mode after the first protection');
      expect(resultInAllowingMode2, true, reason: 'The protector switched to the protection mode by mistake');
      expect(resultInProtectionMode2, false,
          reason: 'The protector did not switched to the protection mode at the first time');
    });

    test('be able to switch in the protection mode after a long period with low events amount', () {
      var start = new DateTime.now();
      var clockMock = new ClockMock();
      when(clockMock.getNow()).thenReturn(start);
      // ignore: deprecated_member_use
      var protector = new InfiniteLoopProtector(clock: clockMock);
      var events = new List.generate(LoggingSpeed.defaultEventsCount - 1, (_) => new Object());

      events.forEach((dynamic event) => protector(event));

      when(clockMock.getNow()).thenReturn(start.add(stepInterval));
      events.forEach((dynamic event) => protector(event));

      when(clockMock.getNow()).thenReturn(start.add(stepInterval * 2));
      events.forEach((dynamic event) => protector(event));
      events.forEach((dynamic event) => protector(event));

      expect(protector(new Object()), false);
    });
  });
}

typedef dynamic TestItem();

class ClockMock extends Mock implements Clock {}
