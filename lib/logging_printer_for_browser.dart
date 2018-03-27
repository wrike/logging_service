import 'package:logging/logging.dart' as log;
import 'package:logging_service/src/js_console_proxy.dart';
import 'package:stack_trace/stack_trace.dart';
import 'dart:html' as html;

class LoggingPrinterForBrowser {
  final bool _shouldTerseErrorWhenPrint;
  final JsConsoleProxy _consoleProxy;

  LoggingPrinterForBrowser({bool shouldTerseErrorWhenPrint: false, JsConsoleProxy consoleProxy})
      : _shouldTerseErrorWhenPrint = shouldTerseErrorWhenPrint,
        _consoleProxy = consoleProxy ?? new JsConsoleProxy();

  void call(log.LogRecord rec) {
    print('### Log: ${rec.sequenceNumber}');
    if (rec.level == log.Level.SEVERE) {
      print('### rec.level: ${rec.level}');
      print('### rec.loggerName: ${rec.loggerName}');
      print('### rec.time: ${rec.time}');
      print('### rec.message: ${rec.message}');
      print('### rec.error: ${rec.error}');
      print('### rec.error.runtimeType: ${rec.error.runtimeType}');
      print('### rec.stackTrace: ${rec.stackTrace}');
      print('### rec.stackTrace.runtimeType: ${rec.stackTrace.runtimeType}');

      if (rec.error is Error) {
        print('### rec.error is Error');
        var stack = (rec.error as Error).stackTrace;
        print('### stack: ${stack.runtimeType}');
        print('### stack.toString():\r\n ${stack.toString()}');
        html.window.console.error(rec.error.toString() + '\r\n' + stack.toString());
      }

      if (rec.stackTrace is Chain) {
        print('### rec.stackTrace is Chain');
        for (var trace in (rec.stackTrace as Chain).traces) {
          print('### trace.original:');
          print(trace.original);
        }
      }

      html.window.console.error(rec.error.toString());
      html.window.console.error(rec.stackTrace.toString());
      html.window.console.error(rec.error.toString() + '\r\n' + rec.stackTrace.toString());
    }

//    var msg = '[${rec.time.toIso8601String()}] ${rec.loggerName}: ${rec.message}';
//
//    if (rec.error != null && rec.error.toString() != rec.message) {
//      msg += '\n' + rec.error.toString();
//    }
//
//    if (rec.level == log.Level.SEVERE) {
//      _consoleProxy.error(msg);
//    } else {
//      _consoleProxy.log(msg);
//    }
//
//    if (rec.stackTrace != null) {
//      String trace;
//
//      if (_shouldTerseErrorWhenPrint) {
//        if (rec.stackTrace is Trace) {
//          trace = (rec.stackTrace as Trace).terse.toString();
//        } else if (rec.stackTrace is Chain) {
//          trace = (rec.stackTrace as Chain).terse.toString();
//        } else {
//          trace = new Trace.from(rec.stackTrace).terse.toString();
//        }
//      } else if (rec.stackTrace is Chain) {
//        _consoleProxy.group('The chained stack trace: ');
//        for (final trace in (rec.stackTrace as Chain).traces) {
//          _consoleProxy.log(_correctFormat(trace.original.toString()));
//        }
//        _consoleProxy.groupEnd();
//      } else if (rec.stackTrace is Trace) {
//        trace = _correctFormat((rec.stackTrace as Trace).original.toString());
//      } else {
//        trace = _correctFormat(rec.stackTrace.toString());
//      }
//
//      if (trace != null) {
//        _consoleProxy.log(trace);
//      }
//    }
  }

  String _correctFormat(String trace) {
    var traceStrings = trace.split(new RegExp(r'(?:\r\n)|(?:\r)|(?:\n)'));

    if (!traceStrings.first.startsWith(new RegExp(r'[A-Za-z]*Error'))) {
      return 'Error: \n$trace';
    }

    return trace;
  }
}
