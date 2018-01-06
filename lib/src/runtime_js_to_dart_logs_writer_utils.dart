@JS()
library runtime_js_to_dart_logs_writer_utils;

import 'package:js/js.dart';

@JS('loggingServiceJsToDartLogsWriter')
external LogWriter get loggingServiceJsToDartLogsWriter;

@JS('loggingServiceJsToDartLogsWriter')
external set loggingServiceJsToDartLogsWriter(LogWriter writer);

@JS('loggingServiceLogWriteBuffer')
external List<List<dynamic>> get loggingServiceLogWriteBuffer;

typedef void LogWriter(List<dynamic> args);

@JS('loggingServiceOriginalConsoleMethods')
@anonymous
class LoggingServiceOriginalConsoleMethods {
  external static void error(String msg);
  external static void info(String msg);
  external static void log(String msg);
}

@JS('loggingServiceOriginalConsoleMethods')
external dynamic get loggingServiceOriginalConsoleContainer;
