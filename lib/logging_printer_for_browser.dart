import 'package:logging/logging.dart' as log;
import 'package:stack_trace/stack_trace.dart';

import 'src/dev_mode.dart';
import 'src/js_console_proxy.dart';

class LoggingPrinterForBrowser {
  static const String separatorString = '\n****************************************************************\n';
  final bool _shouldTerseErrorWhenPrint;
  final JsConsoleProxy _consoleProxy;

  LoggingPrinterForBrowser({bool shouldTerseErrorWhenPrint: false, JsConsoleProxy consoleProxy})
      : _shouldTerseErrorWhenPrint = shouldTerseErrorWhenPrint,
        _consoleProxy = consoleProxy ?? new JsConsoleProxy();

  void call(log.LogRecord rec) {
    var additionalInfo = <String>[];
    var msg = '${rec.sequenceNumber}/${rec.level} [${rec.time.toIso8601String()}] ${rec.loggerName}: ';
    var shouldWeSubstituteMsg = rec.message == null || rec.message.isEmpty;

    if (shouldWeSubstituteMsg) {
      if (rec.error != null && rec.error.toString().isNotEmpty) {
        msg += rec.error.toString();
      } else {
        msg += '<the record.message is empty>';
      }
    } else {
      msg += rec.message;
    }

    if (rec.error != null) {
      if (!shouldWeSubstituteMsg) {
        additionalInfo.add(_makeHeaderString('record.error.toString()'));
        additionalInfo.add(rec.error.toString());
      }

      if (rec.error is Error && (rec.error as Error).stackTrace != null) {
        var stack = (rec.error as Error).stackTrace;

        if (!isWeInDevNode()) {
          additionalInfo.add(_makeHeaderString('record.error.stackTrace.toString()'));
          additionalInfo.add(stack.toString());
        }
      }
    }

    if (rec.stackTrace != null) {
      var stackTraceDesc = 'record.stackTrace';
      var traceStrings = <String>[];

      if (rec.stackTrace is Trace) {
        stackTraceDesc += '<Trace>';
      } else if (rec.stackTrace is Chain) {
        stackTraceDesc += '<Chain>';
      }

      if (_shouldTerseErrorWhenPrint) {
        stackTraceDesc += '<terse>';
      }

      if (isWeInDevNode()) {
        if (_shouldTerseErrorWhenPrint) {
          if (rec.stackTrace is Trace) {
            traceStrings.add((rec.stackTrace as Trace).terse.toString());
          } else if (rec.stackTrace is Chain) {
            traceStrings.add((rec.stackTrace as Chain).terse.toString());
          } else {
            traceStrings.add(new Trace.from(rec.stackTrace).terse.toString());
          }
        } else {
          traceStrings.add(rec.stackTrace.toString());
        }

      } else {
        if (rec.stackTrace is Trace) {
          traceStrings.add(_correctFormat((rec.stackTrace as Trace).original.toString()));
        } else if (rec.stackTrace is Chain) {
          traceStrings.addAll(
            (rec.stackTrace as Chain).traces.map(
                  (Trace trace) => _correctFormat(trace.original.toString()),
                ),
          );
        } else {
          traceStrings.add(_correctFormat(rec.stackTrace.toString()));
        }
      }

      additionalInfo.add(_makeHeaderString(stackTraceDesc));
      additionalInfo.addAll(traceStrings);
    }

    if (isWeInDevNode() && additionalInfo.isNotEmpty) {
      msg += '\n' + additionalInfo.join('\n');
    }

    if (rec.level == log.Level.SEVERE) {
      _consoleProxy.error(msg);
    } else {
      _consoleProxy.log(msg);
    }

    if (additionalInfo.isNotEmpty && !isWeInDevNode()) {
      _consoleProxy.group('${rec.sequenceNumber}/${rec.level} Additional info:');
      for (var msg in additionalInfo) {
        _consoleProxy.log(msg);
      }
      _consoleProxy.groupEnd();
    }

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

  String _makeHeaderString(String info) => '\n***** $info '.padRight(100, '*');
}
