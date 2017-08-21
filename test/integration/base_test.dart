@TestOn('browser')
import 'package:logging_service/configure_logging_for_browser.dart';
import 'package:logging_service/logging_service.dart';
import 'package:test/test.dart';

void main() {
  group('runProtected should', () {
    test('protect from exceptions', () {
      final _loggingService = new LoggingService()..start();

      _loggingService.runProtected(() {
        throw new Exception('testEx');
      });
    });

    test('protect from exceptions after ConfigureLoggingForBrowser.setUpAll was called', () {
      final _loggingService = new LoggingService()..start();

      ConfigureLoggingForBrowser.setUpAll(_loggingService);

      _loggingService.runProtected(() {
        throw new Exception('testEx');
      });
    });

    test('protect from exceptions even when the Sentry server unavailable', () {
      final _loggingService = new LoggingService()..start();

      ConfigureLoggingForBrowser.setUpAll(_loggingService,
          appVersionUid: 'app_uid', sentryDsn: 'https://123456789abcdef123456789abcdef12@sentry.local/1');

      _loggingService.runProtected(() {
        throw new Exception('testEx');
      });
    });
  });
}
