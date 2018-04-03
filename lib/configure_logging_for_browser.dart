import 'dart:convert';
import 'dart:html' as html;

import 'package:logging/logging.dart' as log;
import 'package:sentry_client/sentry_client_browser.dart';
import 'package:sentry_client/sentry_dsn.dart';

import 'infinite_loop_protector.dart';
import 'logging_printer_for_browser.dart';
import 'logging_saver_for_sentry.dart';
import 'logging_service.dart';
import 'protector.dart';
import 'sentry_pre_save_for_browser.dart';
import 'src/dev_mode.dart';
import 'src/js_console_proxy.dart';
import 'src/js_pre_start_errors_list_utils.dart';
import 'src/js_utils.dart';

const _json = const JsonCodec();

typedef bool Protector(dynamic event);

class ConfigureLoggingForBrowser {
  static const String LOG_URL_ARG_NAME = 'logging';
  static final Protector _defaultProtector = new InfiniteLoopProtector();
  static final JsConsoleProxy _consoleProxy = new JsConsoleProxy();

  static void collectPreStartJsErrors(LoggingService loggingService) {
    if (loggingServiceJsPreStartErrorsList is List) {
      loggingServiceJsPreStartErrorsList.forEach((error) {
        if (error is! html.Event) {
          loggingService.handleLogRecord(
            new log.LogRecord(
              log.Level.SEVERE,
              'collectPreStartJsErrors: the error event has incorrect type: ${error.runtimeType}/${error.toString()}',
              'jsPreStartUnhandledErrorLogger',
              error,
            ),
          );
          return null;
        }

        _handleJsError(error as html.Event, loggingService, 'jsPreStartUnhandledErrorLogger');
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
      if (!RepeatProtector.shouldBeHandled(error)) {
        return null;
      }

      if (error is! html.Event) {
        loggingService.handleLogRecord(
          new log.LogRecord(
            log.Level.SEVERE,
            'window.onError was called with incorrect arguments, the error event: ${error.toString()}',
            'jsUnhandledErrorLogger',
            error,
          ),
        );
        return null;
      }

      if (preventDefault) {
        error.preventDefault();
      }

      if (infiniteLoopProtector != null && !infiniteLoopProtector(error)) {
        _consoleProxy.log('The handling of js-errors was disabled by the infinity-loop protector');
        return null;
      }

      if (!preventDefault && isWeInDevNode()) {
        return null;
      }

      _handleJsError(error, loggingService, 'jsUnhandledErrorLogger');
    });
  }

  static void setLogLevelsFromUrl(LoggingService loggingService, {html.Window window}) {
    window = window ?? html.window;
    // ignore: strong_mode_uses_dynamic_as_bottom
    final _levelNames = new Map.fromIterable(log.Level.LEVELS, key: (log.Level l) => l.name, value: (log.Level l) => l);

    final applyLogLevel = () {
      final hash = window.location.hash.replaceFirst('#', '');
      final query = Uri.splitQueryString(hash);

      if (query.isNotEmpty && query.containsKey(LOG_URL_ARG_NAME)) {
        final argsRaw = query[LOG_URL_ARG_NAME];

        final args = _json.decode(argsRaw) as Map<String, String>;

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
//    collectPreStartJsErrors(loggingService);
  }

  static void _handleJsError(html.Event errorEvent, LoggingService loggingService, String loggerName) {
    String errorMsg;
    var errorData = <String, String>{};

    try {
      StackTrace stackTrace;

      if (errorEvent is html.ErrorEvent) {
        errorData['filename'] = errorEvent.filename;
        errorData['lineno'] = errorEvent.lineno.toString();
        errorData['type'] = errorEvent.type;
        errorData['timeStamp'] = errorEvent.timeStamp.toString();

        if (errorEvent.message != null && errorEvent.message.toString().isNotEmpty) {
          errorMsg = errorEvent.message.toString();
        }

        if (errorEvent.error != null) {
          if (errorEvent.error is String) {
            stackTrace = new StackTrace.fromString(errorEvent.error.toString());
          } else {
            try {
              var nestedStackTrace = (errorEvent.error as JsError).stack;
              if (stackTrace == null && nestedStackTrace != null) {
                stackTrace = new StackTrace.fromString(nestedStackTrace.toString());
              }

              var nestedMessage = (errorEvent.error as JsError).message;
              if (nestedMessage != null && nestedMessage.isNotEmpty) {
                if (errorMsg == null) {
                  errorMsg = nestedMessage;
                } else if (!errorMsg.contains(nestedMessage)) {
                  errorMsg += '\n $nestedMessage';
                }
              }
            } catch (e) {
              /// We are here because errorEvent.error is not a JsObject and JsInterop failed.
            }

            if (errorMsg == null && errorEvent.error.toString().isNotEmpty) {
              errorMsg = errorEvent.error.toString();
            }
          }
        }
      }

      if (errorMsg == null) {
        errorMsg = errorEvent.toString();
      }

      loggingService.handleLogRecord(new log.LogRecord(log.Level.SEVERE, errorMsg, loggerName, errorData, stackTrace));
    } catch (exception) {
      if (errorEvent is html.ErrorEvent) {
        errorData['message'] = errorEvent.message.toString();
      }

      errorMsg = 'The error from js was not parsed correctly, the errorData: ${errorData.toString()}';
      loggingService.handleLogRecord(new log.LogRecord(log.Level.SEVERE, errorMsg, loggerName, exception));
    }
  }
}
