import 'dart:convert';
import 'dart:html' as html;

import 'package:logging/logging.dart' as log;
import 'package:logging_service/infinite_loop_protector.dart';
import 'package:logging_service/src/configure_js_to_dart_logs_writer.dart';
import 'package:logging_service/src/js_console_proxy.dart';
import 'package:logging_service/src/js_utils.dart';
import 'package:sentry_client/sentry_client_browser.dart';
import 'package:sentry_client/sentry_dsn.dart';

import 'logging_printer_for_browser.dart';
import 'logging_saver_for_sentry.dart';
import 'logging_service.dart';
import 'sentry_pre_save_for_browser.dart';
import 'src/js_pre_start_errors_list_utils.dart';

typedef bool Protector(dynamic event);

class ConfigureLoggingForBrowser {
  static const String LOG_URL_ARG_NAME = 'logging';
  static final Protector _defaultProtector = new InfiniteLoopProtector();
  static final JsConsoleProxy _consoleProxy = new JsConsoleProxy();

  static void collectPreStartJsErrors(LoggingService loggingService) {
    if (loggingServiceJsPreStartErrorsList is List) {
      loggingServiceJsPreStartErrorsList.forEach((error) {
        loggingService.handleLogRecord(new log.LogRecord(log.Level.SEVERE, error.error.toString(),
            'jsPreStartUnhandledErrorLogger', error.error, new StackTrace.fromString(error.error.stack)));
      });
      loggingServiceIsJsPreStartErrorSavingEnabled = false;
      loggingServiceJsPreStartErrorsList.clear();
    }
  }

  static void listenJsErrors(LoggingService loggingService,
      {bool preventDefault: true, html.Window window, Protector infiniteLoopProtector}) {
    window = window ?? html.window;
    infiniteLoopProtector = infiniteLoopProtector ?? _defaultProtector;

    window.onError.listen((html.Event error) {
      if (preventDefault) {
        error.preventDefault();
      }

      if (infiniteLoopProtector != null && !infiniteLoopProtector(error)) {
        _consoleProxy.log('The handling of js-errors was disabled by the infinity-loop protector');
        return null;
      }

      if (error is html.ErrorEvent) {
        String stackTrace;

        if (error.error is String) {
          stackTrace = error.error.toString();
        } else {
          stackTrace = (error.error as JsError).stack;
        }

        loggingService.handleLogRecord(new log.LogRecord(log.Level.SEVERE, error.error.toString(),
            'jsUnhandledErrorLogger', error, new StackTrace.fromString(stackTrace)));
      } else {
        loggingService.handleLogRecord(new log.LogRecord(log.Level.SEVERE, error.toString(), 'jsUnhandledErrorLogger',
            error, new StackTrace.fromString(error.toString())));
      }
    });
  }

  static void setLogLevelsFromUrl(LoggingService loggingService, {html.Window window}) {
    window = window ?? html.window;
    final _levelNames = new Map.fromIterable(log.Level.LEVELS, key: (log.Level l) => l.name, value: (log.Level l) => l);

    final applyLogLevel = () {
      final hash = window.location.hash.replaceFirst('#', '');
      final query = Uri.splitQueryString(hash);

      if (query.isNotEmpty && query.containsKey(LOG_URL_ARG_NAME)) {
        final argsRaw = query[LOG_URL_ARG_NAME];

        final args = JSON.decode(argsRaw) as Map<String, String>;

        args.forEach((String loggerName, String level) {
          if (_levelNames.containsKey(level)) {
            loggingService.setLogLevelPerLogger(loggerName, _levelNames[level]);
          }
        });
      }
    };

    html.window.addEventListener('hashchange', (html.Event _) {
      applyLogLevel();
    });
    applyLogLevel();
  }

  static void setUpAll(
    LoggingService loggingService, {
    bool shouldTerseErrorWhenPrint: false,
    List<LoggingHandler> customLoggingPrinters,
    String appVersionUid,
    String sentryDsn,
    List<SentryPacketPreSaveHandler> customPreSaveHandlers,
    List<LoggingHandler> customLoggingSavers,
    bool preventDefaultJsError: true,
    Protector jsInfiniteLoopProtector,
  }) {
    loggingService
        .addLoggingPrinter(new LoggingPrinterForBrowser(shouldTerseErrorWhenPrint: shouldTerseErrorWhenPrint));
    if (customLoggingPrinters != null) {
      customLoggingPrinters.forEach((LoggingHandler handler) => loggingService.addLoggingPrinter(handler));
    }

    if (appVersionUid != null && sentryDsn != null) {
      var loggingSaverForSentry =
          new LoggingSaverForSentry(appVersionUid, new SentryClientBrowser(SentryDsn.fromString(sentryDsn)))
            ..addPreSaveHandlers([new SentryPreSaveForBrowser()]);

      if (customPreSaveHandlers != null) {
        loggingSaverForSentry.addPreSaveHandlers(customPreSaveHandlers);
      }

      loggingService.addLoggingSavers([loggingSaverForSentry]);
    }

    if (customLoggingSavers != null) {
      loggingService.addLoggingSavers(customLoggingSavers);
    }

    setLogLevelsFromUrl(loggingService);
    listenJsErrors(loggingService,
        preventDefault: preventDefaultJsError, infiniteLoopProtector: jsInfiniteLoopProtector);
    collectPreStartJsErrors(loggingService);
    //configureJsToDartLogsWriter(loggingService);
  }
}
