import 'dart:html' as html;

import 'package:logging/logging.dart' as log;
import 'package:stack_trace/stack_trace.dart';

class LoggingPrinterForBrowser {
  final bool _shouldTerseErrorWhenPrint;
  final html.Window _window;

  LoggingPrinterForBrowser({bool shouldTerseErrorWhenPrint: false, html.Window window})
      : _shouldTerseErrorWhenPrint = shouldTerseErrorWhenPrint,
        _window = window ?? html.window;

  void call(log.LogRecord rec) {
    var msg = '[${new DateTime.now().toIso8601String()}] ${rec.loggerName}: ${rec.message}';

    if (rec.error != null && rec.error.toString() != rec.message) {
      msg += '\n' + rec.error.toString();
    }

    if (rec.level == log.Level.SHOUT) {
      _window.console.error(msg);
    } else {
      _window.console.log(msg);
    }

    if (rec.stackTrace != null) {
      String trace;

      if (_shouldTerseErrorWhenPrint) {
        if (rec.stackTrace is Trace) {
          trace = (rec.stackTrace as Trace).terse.toString();
        } else if (rec.stackTrace is Chain) {
          trace = (rec.stackTrace as Chain).terse.toString();
        } else {
          trace = new Trace.from(rec.stackTrace).terse.toString();
        }
      } else if (rec.stackTrace is Chain) {
        _window.console.group('The chained stack trace: ');
        for (final trace in (rec.stackTrace as Chain).traces) {
          _window.console.log(_correctFormat(trace.original.toString()));
        }
        _window.console.groupEnd();
      } else if (rec.stackTrace is Trace) {
        trace = _correctFormat((rec.stackTrace as Trace).original.toString());
      } else {
        trace = _correctFormat(rec.stackTrace.toString());
      }

      if (trace != null) {
        _window.console.log(trace);
      }
    }
  }

  String _correctFormat(String trace) {
    var traceStrings = trace.split(new RegExp(r'(?:\r\n)|(?:\r)|(?:\n)'));

    if (!traceStrings.first.startsWith(new RegExp(r'[A-Za-z]*Error'))) {
      return 'Error: \n$trace';
    }

    return trace;
  }
}
