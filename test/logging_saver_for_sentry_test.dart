@TestOn('browser')
import 'dart:async';
import 'dart:html' as html;
import 'dart:html_common' as html_common;

import 'package:logging/logging.dart' as log;
import 'package:logging_service/configure_logging_for_browser.dart';
import 'package:logging_service/logging_saver_for_sentry.dart';
import 'package:logging_service/logging_service.dart';
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
      var chain = new Chain([new Trace.from(testTrace), new Trace.from(testTrace)]);

      var record = new log.LogRecord(
        testLogLevel,
        testLogMsg,
        testLoggerName,
        null,
        chain,
      );

      saver(record);
      print(chain.toString());
      print(chain.traces.first.original);

      // ignore: argument_type_not_assignable
      var packet = verify(sentryClientMock.write(captureAny)).captured.first as SentryPacket;
    });
  });
}

class SentryClientMock extends Mock implements SentryClient {}
