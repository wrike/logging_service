import 'dart:html' as html;

import 'package:logging/logging.dart' as log;
import 'package:logging_service/logging_printer_for_browser.dart';
import 'package:logging_service/logging_service.dart';
import 'package:logging_service/src/configure_js_to_dart_logs_writer.dart';
import 'package:test/test.dart';

void main() {
  group('runProtected should', () {
    test('protect from exceptions', () {
      print('use "print()" from Dart');

      final loggingService = new LoggingService();
      loggingService.start(rootLogLevel: log.Level.ALL);
      loggingService.addLoggingPrinter(new LoggingPrinterForBrowser());

      configureJsToDartLogsWriter(loggingService);

      html.window.console.log('use "window.console.log" from Dart');
    });
  });
}
