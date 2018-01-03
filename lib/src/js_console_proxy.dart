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
        if (LoggingServiceOriginalConsoleMethods.error != null) {
          LoggingServiceOriginalConsoleMethods.error(msg);
        } else {
          html.window.console.error(msg);
        }
        break;
      case _LogLevel.Info:
        if (LoggingServiceOriginalConsoleMethods.info != null) {
          LoggingServiceOriginalConsoleMethods.info(msg);
        } else {
          html.window.console.info(msg);
        }
        break;
      case _LogLevel.Log:
        if (LoggingServiceOriginalConsoleMethods.log != null) {
          LoggingServiceOriginalConsoleMethods.log(msg);
        } else {
          html.window.console.log(msg);
        }
        break;
    }
  }
}

enum _LogLevel { Error, Info, Log }
