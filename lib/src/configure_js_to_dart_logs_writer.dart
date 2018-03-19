@JS()
library configure_js_to_dart_logs_writer;

import 'dart:js';

import 'package:js/js.dart';
import 'package:logging/logging.dart' as log;
import 'package:logging_service/logging_service.dart';
import 'package:logging_service/src/js_utils.dart';
import 'package:logging_service/src/runtime_js_to_dart_logs_writer_utils.dart';

const String JsToDartLogsLoggerName = 'FromWindowConsole';

void configureJsToDartLogsWriter(LoggingService loggingService) {
  //TODO: refactor with import 'dart:js';
  loggingServiceJsToDartLogsWriter = allowInterop((List<dynamic> args) {
    if (args.isEmpty) {
      return null;
    }

    args = args.sublist(0);

    final level = (() {
      switch (args.removeAt(0) as String) {
        case 'error':
          return log.Level.SEVERE;
        case 'info':
          return log.Level.WARNING;
        case 'log':
        default:
          return log.Level.INFO;
      }
    })();

    final error = (() {
      for (var i = 0; i < args.length; i++) {
        Object arg = args[i];
        if (isItJsObject(arg) && (arg as JsErrorEvent).error != null) {
          arg = (arg as JsErrorEvent).error;
        }

        if (isItJsObject(arg) && (arg as JsError).stack != null && (arg as JsError).message != null) {
          args.removeAt(i);
          return arg as JsError;
        }
      }
    })();

    args = args.map<String>((dynamic arg) => isItJsObject(arg) ? jsonStringify(arg) : arg.toString()).toList();

    final msg = args.join('\r\n');

    log.LogRecord logRecord;

    if (error != null) {
      logRecord = new log.LogRecord(level, msg, JsToDartLogsLoggerName, error, new StackTrace.fromString(error.stack));
    } else {
      logRecord = new log.LogRecord(level, msg, JsToDartLogsLoggerName);
    }

    loggingService.handleLogRecord(logRecord);
  });

  if (loggingServiceLogWriteBuffer.isNotEmpty) {
    loggingServiceLogWriteBuffer.forEach(loggingServiceJsToDartLogsWriter);
  }
}
