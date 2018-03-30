import 'dart:convert';
import 'dart:html' as html;
import 'dart:js';
import 'dart:html_common' as html_com;

import 'dart:nativewrappers';
import 'package:logging/logging.dart' as log;
import 'package:logging_service/infinite_loop_protector.dart';
import 'package:logging_service/protector.dart';
import 'package:logging_service/src/js_console_proxy.dart';
import 'package:logging_service/src/js_utils.dart';
import 'package:sentry_client/sentry_client_browser.dart';
import 'package:sentry_client/sentry_dsn.dart';

import 'logging_printer_for_browser.dart';
import 'logging_saver_for_sentry.dart';
import 'logging_service.dart';
import 'sentry_pre_save_for_browser.dart';
import 'src/js_pre_start_errors_list_utils.dart';

const _json = const JsonCodec();

typedef bool Protector(dynamic event);

class ConfigureLoggingForBrowser {
  static const String LOG_URL_ARG_NAME = 'logging';
  static final Protector _defaultProtector = new InfiniteLoopProtector();
  static final JsConsoleProxy _consoleProxy = new JsConsoleProxy();

  static void collectPreStartJsErrors(LoggingService loggingService) {
    print('### collectPreStartJsErrors');
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
    print('### listenJsErrors:preventDefault: ${preventDefault}');

    window.onError.listen((html.Event error) {
      print('### window.onError-> error.hashCode: ${error.hashCode}');

      if (!RepeatProtector.shouldBeHandled(error)) {
        print('### listenJsErrors->!RepeatProtector.shouldBeHandled(error)');
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

//      if (preventDefault) {
//        print('### preventDefault');
//        error.preventDefault();
//      }

      if (infiniteLoopProtector != null && !infiniteLoopProtector(error)) {
        _consoleProxy.log('The handling of js-errors was disabled by the infinity-loop protector');
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
    print('### _handleJsError->');
    print('### errorEvent.runtimeType: ${errorEvent.runtimeType}');
    print('### errorEvent.toString(): ${errorEvent.toString()}');
    if (errorEvent is html.ErrorEvent) {
      print('### errorEvent.error.runtimeType: ${errorEvent.error.runtimeType}');
      print('### errorEvent.error is NativeFieldWrapperClass2: ${errorEvent.error is NativeFieldWrapperClass2}');
      print('### errorEvent.error is JsObject: ${errorEvent.error is JsObject}');
      print('### errorEvent.error.toString(): ${errorEvent.error.toString()}');
      print('### errorEvent.message: ${errorEvent.message}');
      print('### errorEvent.lineno: ${errorEvent.lineno}');
      print('### errorEvent.filename: ${errorEvent.filename}');
    }

    try {
      String errorMsg;
      StackTrace stackTrace;

      if (errorEvent is html.ErrorEvent) {
        if (errorEvent.message != null && errorEvent.message.toString().isNotEmpty) {
          print('### errorMsg = errorEvent.message.toString();');
          errorMsg = errorEvent.message.toString();
        }

        if (errorEvent.error is String) {
          print('### errorEvent.error is String');
          print('### try to parse the stack');
          stackTrace = new StackTrace.fromString(errorEvent.error.toString());
          print(stackTrace.toString());
        }

        if (errorEvent.error != null) {
          try {
            print('### try get nsested error!');
            var nestedJsError = new JsObject.fromBrowserObject(errorEvent.error);
            print('### nestedJsError.toString(): ${nestedJsError.toString()}');
            if (nestedJsError['stack'] != null) {
              print("### nestedJsError['stack'] != null");
              stackTrace = new StackTrace.fromString(nestedJsError['stack'].toString());
              print("### stackTrace.toString(): ${stackTrace.toString()}");
            }
            if (errorMsg == null &&
                nestedJsError['message'] != null &&
                nestedJsError['message'].toString().isNotEmpty) {
              print("### errorMsg == null && nestedJsError['message'] != null");
              print("### errorMsg = nestedJsError['message'].toString();");
              errorMsg = nestedJsError['message'].toString();
            }

            print('### try use interop');
            print('### (errorEvent.error as JsError).stack: ${(errorEvent.error as JsError).stack}');
            if (stackTrace == null && (errorEvent.error as JsError).stack != null) {
              print("### stackTrace == null && (errorEvent.error as JsError).stack != null");
              stackTrace = new StackTrace.fromString(nestedJsError['stack'].toString());
            }
            print('### (errorEvent.error as JsError).message: ${(errorEvent.error as JsError).message}');

            print('### the nested error has been successfully handled');
          } catch (e) {
            print('### nestedJsError->exception');
          }

          if (errorMsg == null && errorEvent.error.toString().isNotEmpty) {
            print('### errorMsg = errorEvent.error.toString();');
            errorMsg = errorEvent.error.toString();
          }
        }
      }

      if (errorMsg == null) {
        print('errorMsg = errorEvent.toString()');
        errorMsg = errorEvent.toString();
      }

      loggingService.handleLogRecord(
        new log.LogRecord(
          log.Level.SEVERE,
          errorMsg,
          loggerName,
          errorEvent,
          stackTrace,
        ),
      );
    } catch (e) {
      print('###  catch in _handleJsError!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!');
      loggingService.handleLogRecord(
        new log.LogRecord(
          log.Level.SEVERE,
          'The error from js was not parsed correctly, the error: ${errorEvent.toString()}',
          loggerName,
          e,
        ),
      );
    }
  }
}
