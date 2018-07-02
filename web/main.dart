
import 'package:logging/logging.dart';
import 'package:logging_service/configure_logging_for_browser.dart';
import 'package:logging_service/logging_service.dart';

void main() {
  print('main file');

  final loggingService = new LoggingService()..start();

  ConfigureLoggingForBrowser.setUpAll(
    loggingService,
    appVersionUid: 'app_uid',
    sentryDsn: 'https://123456789abcdef123456789abcdef12@sentry.local/1'
  );

  loggingService.runProtected(() {
    //Your own app code
    var logger1 = new Logger('myModuleName1');
    logger1.info('Some info');

    var logger2 = new Logger('myModuleName2');
    logger2.severe('Some error! We should fix it!');
    logger2.shout('Some dev-message');
  });
}
