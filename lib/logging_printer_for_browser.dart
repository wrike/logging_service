import 'package:logging/logging.dart' as log;
import 'package:logging_service/src/js_console_proxy.dart';
import 'package:stack_trace/stack_trace.dart';

class LoggingPrinterForBrowser {
  final bool _shouldTerseErrorWhenPrint;
  final JsConsoleProxy _consoleProxy;

  LoggingPrinterForBrowser({bool shouldTerseErrorWhenPrint: false, JsConsoleProxy consoleProxy})
      : _shouldTerseErrorWhenPrint = shouldTerseErrorWhenPrint,
        _consoleProxy = consoleProxy ?? new JsConsoleProxy();

  void call(log.LogRecord rec) {
    var msg = '[${rec.time.toIso8601String()}] ${rec.loggerName}: ${rec.message}';

    if (rec.error != null && rec.error.toString() != rec.message) {
      msg += '\n' + rec.error.toString();
    }

    if (rec.level == log.Level.SHOUT) {
      _consoleProxy.error(msg);
    } else {
      _consoleProxy.log(msg);
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
        _consoleProxy.group('The chained stack trace: ');
        for (final trace in (rec.stackTrace as Chain).traces) {
          _consoleProxy.log(_correctFormat(trace.original.toString()));
        }
        _consoleProxy.groupEnd();
      } else if (rec.stackTrace is Trace) {
        trace = _correctFormat((rec.stackTrace as Trace).original.toString());
      } else {
        trace = _correctFormat(rec.stackTrace.toString());
      }

      if (trace != null) {
        _consoleProxy.log(trace);
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
