import 'dart:html' as html;

import 'package:logging_service/src/runtime_js_to_dart_logs_writer_utils.dart';

class JsConsoleProxy {
  void error(String msg) => _writeToConsole(_LogLevel.Error, msg);

  void group(String msg) => html.window.console.group(msg);

  void groupEnd() => html.window.console.groupEnd();

  void info(String msg) => _writeToConsole(_LogLevel.Info, msg);

  void log(String msg) => _writeToConsole(_LogLevel.Log, msg);

  void _writeToConsole(_LogLevel level, String msg) {
    switch (level) {
      case _LogLevel.Error:
        if (_doesExist(LoggingServiceOriginalConsoleMethods.error)) {
          LoggingServiceOriginalConsoleMethods.error(msg);
        } else {
          html.window.console.error(msg);
        }
        break;
      case _LogLevel.Info:
        if (_doesExist(LoggingServiceOriginalConsoleMethods.info)) {
          LoggingServiceOriginalConsoleMethods.info(msg);
        } else {
          html.window.console.info(msg);
        }
        break;
      case _LogLevel.Log:
        if (_doesExist(LoggingServiceOriginalConsoleMethods.log)) {
          LoggingServiceOriginalConsoleMethods.log(msg);
        } else {
          html.window.console.log(msg);
        }
        break;
    }
  }

  bool _doesExist(dynamic method) => loggingServiceOriginalConsoleContainer != null && method != null;
}

enum _LogLevel { Error, Info, Log }
