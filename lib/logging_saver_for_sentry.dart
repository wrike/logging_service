import 'package:logging/logging.dart' as log;
import 'package:sentry_client/api_data/sentry_exception.dart';
import 'package:sentry_client/api_data/sentry_packet.dart';
import 'package:sentry_client/api_data/sentry_stacktrace.dart';
import 'package:sentry_client/api_data/sentry_stacktrace_frame.dart';
import 'package:sentry_client/sentry_client.dart';
import 'package:stack_trace/stack_trace.dart';

import 'logging_environment.dart';

typedef void SentryPacketPreSaveHandler(SentryPacket packet);

class LoggingSaverForSentry {
  final String _appVersionUid;
  final SentryClient _sentry;
  final List<SentryPacketPreSaveHandler> _preSaveHandlers = [];

  LoggingSaverForSentry(String appVersionUid, SentryClient sentry)
      : _appVersionUid = appVersionUid,
        _sentry = sentry;

  void addPreSaveHandlers(Iterable<SentryPacketPreSaveHandler> handlers) {
    _preSaveHandlers.addAll(handlers);
  }

  void call(log.LogRecord rec) {
    if (_sentry == null) {
      return;
    }

    var packet = new SentryPacket(
      logger: rec.loggerName,
      release: _appVersionUid,
      environment: LoggingEnvironment.remote.value,
      exceptionValues: getSentryExceptionValuesByLogRecord(rec),
    );

    if (rec.error is Map<String, String>) {
      packet.extra.addAll(rec.error as Map<String, String>);
    }

    for (final handler in _preSaveHandlers) {
      handler(packet);
    }

    _sentry.write(packet);
  }

  static List<SentryException> getSentryExceptionValuesByLogRecord(log.LogRecord record) {
    print('### getSentryExceptionValuesByLogRecord');
    String exceptionValue;
    String exceptionType;

    if (record.stackTrace == null) {
      return <SentryException>[];
    }

    print('### record.stackTrace != null');
    var traceString = record.stackTrace.toString();
    print(traceString);

    if (traceString.indexOf(':') > 0) {
      print("### traceString.indexOf(':') > 0");
      exceptionType = traceString.split(':').first;
      print('### exceptionType: $exceptionType');
    }

    if (record.message != null && record.message.isNotEmpty) {
      exceptionValue = record.message;
    } else if (record.error != null && record.error.toString().isNotEmpty) {
      exceptionValue = record.error.toString();
    }

    if (record.stackTrace is Chain) {
      return (record.stackTrace as Chain)
          .traces
          .map((Trace trace) => new SentryException(
              type: exceptionType, value: exceptionValue, stacktrace: getSentryTraceFromParsedTrace(trace)))
          .toList();
    } else if (record.stackTrace is Trace) {
      return [
        new SentryException(
          type: exceptionType,
          value: exceptionValue,
          stacktrace: getSentryTraceFromParsedTrace(record.stackTrace as Trace),
        )
      ];
    } else {
      return [
        new SentryException(
          type: exceptionType,
          value: exceptionValue,
          stacktrace: getSentryTraceFromParsedTrace(new Trace.from(record.stackTrace)),
        )
      ];
    }
  }

  static SentryStacktrace getSentryTraceFromParsedTrace(Trace trace) {
    final sentryFrames = <SentryStacktraceFrame>[];

    for (final frame in trace.frames) {
      sentryFrames.add(new SentryStacktraceFrame(
        filename: frame.uri.toString(),
        function: frame.member,
        module: frame.package,
        lineno: frame.line,
        colno: frame.column,
        absPath: frame.uri.toString(),
      ));
    }

    return new SentryStacktrace(frames: sentryFrames);
  }
}
