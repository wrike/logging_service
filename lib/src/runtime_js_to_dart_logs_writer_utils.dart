@JS()
library runtime_js_to_dart_logs_writer_utils;

import 'package:js/js.dart';

@JS('loggingServiceOriginalConsoleMethods')
@anonymous
class LoggingServiceOriginalConsoleMethods {
  external static void error(String msg);
  external static void info(String msg);
  external static void log(String msg);
}

@JS('loggingServiceLogWriteBuffer')
external List<List<dynamic>> get loggingServiceLogWriteBuffer;

@JS('loggingServiceJsToDartLogsWriter')
external LogWriter get loggingServiceJsToDartLogsWriter;
@JS('loggingServiceJsToDartLogsWriter')
external set loggingServiceJsToDartLogsWriter(LogWriter writer);

typedef void LogWriter(List<dynamic> args);

