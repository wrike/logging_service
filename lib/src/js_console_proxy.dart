import 'dart:html' as html;

import 'package:logging_service/src/runtime_js_to_dart_logs_writer_utils.dart';

class JsConsoleProxy {
  void error(String msg) => _writeToConsole(_LogLevel.Error, msg);

  void group(String msg) => html.window.console.group(msg);

  void groupEnd() => html.window.console.groupEnd();

  void info(String msg) => _writeToConsole(_LogLevel.Info, msg);

  void log(String msg) => _writeToConsole(_LogLevel.Log, msg);

  bool _doesExist(dynamic method) => loggingServiceOriginalConsoleContainer != null && method != null;

  void _writeToConsole(_LogLevel level, String msg) {
    switch (level) {
      case _LogLevel.Error:
        var errorMethod = null;
        try {
          errorMethod = LoggingServiceOriginalConsoleMethods.error;
        } catch (e) {
        }
        if (_doesExist(errorMethod)) {
          errorMethod(msg);
        } else {
          html.window.console.error(msg);
        }
        break;
      case _LogLevel.Info:
        var infoMethod = null;
        try {
          infoMethod = LoggingServiceOriginalConsoleMethods.info;
        } catch (e) {
        }
        if (_doesExist(infoMethod)) {
          infoMethod(msg);
        } else {
          html.window.console.info(msg);
        }
        break;
      case _LogLevel.Log:
        var logMethod = null;
        try {
          logMethod = LoggingServiceOriginalConsoleMethods.log;} catch (e) {
        }
        if (_doesExist(logMethod)) {
          logMethod(msg);
        } else {
          html.window.console.log(msg);
        }
        break;
    }
  }
}

enum _LogLevel { Error, Info, Log }
