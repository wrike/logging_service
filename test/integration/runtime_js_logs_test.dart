import 'dart:html' as html;

import 'package:logging/logging.dart' as log;
import 'package:logging_service/logging_printer_for_browser.dart';
import 'package:logging_service/logging_service.dart';
import 'package:logging_service/src/configure_js_to_dart_logs_writer.dart';
import 'package:test/test.dart';

void main() {
  group('errors from js should', () {
    test('be proxied to the Dart printer', () {
      final loggingPrinterForBrowserMock = new LoggingPrinterForBrowserMock();

      print('use "print()" from Dart');

      final loggingService = new LoggingService();
      loggingService.start(rootLogLevel: log.Level.ALL);
      loggingService.addLoggingPrinter(loggingPrinterForBrowserMock);

      configureJsToDartLogsWriter(loggingService);

      html.window.console.log('use "window.console.log" from Dart');

      final errorLogFromJs = loggingPrinterForBrowserMock.mf_captured
          .firstWhere((log.LogRecord record) => record.message == 'Exception note');
      expect(errorLogFromJs.error.toString(), 'ReferenceError: _nonexistentMethod is not defined');
      expect(errorLogFromJs.level, log.Level.SHOUT); //TODO: change to Severe
      expect(errorLogFromJs.loggerName, JsToDartLogsLoggerName);

      final infoLogFromJs1 =
          loggingPrinterForBrowserMock.mf_captured.firstWhere((log.LogRecord record) => record.message == '{}');
      expect(infoLogFromJs1.level, log.Level.WARNING);
      expect(infoLogFromJs1.loggerName, JsToDartLogsLoggerName);

      final infoLogFromJs2 = loggingPrinterForBrowserMock.mf_captured
          .firstWhere((log.LogRecord record) => record.message == '{"error":"some error-like object"}');
      expect(infoLogFromJs2.level, log.Level.WARNING);
      expect(infoLogFromJs2.loggerName, JsToDartLogsLoggerName);

      final printFromDart = loggingPrinterForBrowserMock.mf_captured
          .firstWhere((log.LogRecord record) => record.message == 'use "print()" from Dart');
      expect(printFromDart.level, log.Level.INFO);
      expect(printFromDart.loggerName, JsToDartLogsLoggerName);

      final consoleLogFromDart = loggingPrinterForBrowserMock.mf_captured
          .firstWhere((log.LogRecord record) => record.message == 'use "window.console.log" from Dart');
      expect(consoleLogFromDart.level, log.Level.INFO);
      expect(consoleLogFromDart.loggerName, JsToDartLogsLoggerName);
    });
  });
}

class LoggingPrinterForBrowserMock implements LoggingPrinterForBrowser {
  // The mockito does not work correct with callable classes!
  // ignore: non_constant_identifier_names
  List<log.LogRecord> mf_captured = [];

  @override
  void call(log.LogRecord rec) {
    mf_captured.add(rec);
  }
}
