@TestOn('browser')
import 'package:logging/logging.dart' as log;
import 'package:logging_service/logging_saver_for_sentry.dart';
import 'package:mockito/mockito.dart';
import 'package:sentry_client/api_data/sentry_packet.dart';
import 'package:sentry_client/sentry_client.dart';
import 'package:stack_trace/stack_trace.dart';
import 'package:test/test.dart';

import 'test_stacks.dart';

void main() {
  const testAppVersionUid = '123uid';
  const testLogMsg = 'testLogRecordMsg';
  const testLogLevel = log.Level.INFO;
  const testLoggerName = 'testLoggerName';

  group('LoggingSaverForSentry should', () {
    SentryClientMock sentryClientMock;
    LoggingSaverForSentry saver;

    setUp(() {
      sentryClientMock = new SentryClientMock();

      saver = new LoggingSaverForSentry(testAppVersionUid, sentryClientMock);
    });

    test('extract info from Chain objects', () {
      var testTrace = new StackTrace.fromString(testStack);
      var record = new log.LogRecord(
        testLogLevel,
        testLogMsg,
        testLoggerName,
        null,
        new Chain([new Trace.from(testTrace), new Trace.from(testTrace)]),
      );

      saver(record);

      // ignore: argument_type_not_assignable
      var packet = verify(sentryClientMock.write(captureAny)).captured.first as SentryPacket;
      expect(packet.exceptionValues.length, 2);
      expect(packet.exceptionValues.first.type, 'TestExceptionType');
    });
  });
}

class SentryClientMock extends Mock implements SentryClient {}
