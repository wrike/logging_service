import 'package:logging/logging.dart' as log;
import 'package:stack_trace/stack_trace.dart';

typedef void LoggingHandler(log.LogRecord rec);

class LoggingService {
  static const String ROOT_LOG_LEVEL_KEY = 'rootLogLevel';
  static const String DART_CAPTURED_LOGGER_NAME = 'dartCapturedLogger';

  final Map<String, log.Level> _logLevelsPerLogger = {};
  final List<LoggingHandler> _loggingPrinters = [];
  final List<LoggingHandler> _loggingSavers = [];

  bool _isServiceStarted = false;
  log.Level _savableLogLevel;

  bool get isServiceStarted => _isServiceStarted;

  void addLoggingPrinter(LoggingHandler printer) {
    _loggingPrinters.add(printer);
  }

  void addLoggingSavers(Iterable<LoggingHandler> savers) {
    _loggingSavers.addAll(savers);
  }

  void handleLogRecord(log.LogRecord rec) {
    if (rec.level >= _getLogLevelForModule(rec)) {
      for (final printer in _loggingPrinters) {
        printer(rec);
      }
    }

    if (rec.level >= _savableLogLevel) {
      for (final saver in _loggingSavers) {
        saver(rec);
      }
    }
  }

  T runProtected<T>(T callback(), {bool reThrowErrors: false, bool when: true}) {
    return Chain.capture<T>(callback, when: when, onError: (dynamic error, Chain chain) {
      handleLogRecord(new log.LogRecord(log.Level.SHOUT, error.toString(), DART_CAPTURED_LOGGER_NAME, error, chain));

      if (reThrowErrors) {
        throw error;
      }
    });
  }

  void setLogLevelPerLogger(String loggerName, log.Level level) {
    _logLevelsPerLogger[loggerName] = level;
  }

  void start({
    log.Level rootLogLevel: log.Level.SHOUT,
    log.Level savableLogLevel: log.Level.SHOUT,
    log.Level recordStackTraceAtLevel: log.Level.SHOUT,
  }) {
    if (_isServiceStarted) {
      throw new Exception('The service is already started');
    }

    _logLevelsPerLogger[ROOT_LOG_LEVEL_KEY] = rootLogLevel;
    _savableLogLevel = savableLogLevel;

    log.Logger.root.level = log.Level.ALL;
    log.recordStackTraceAtLevel = recordStackTraceAtLevel;
    log.Logger.root.onRecord.listen(handleLogRecord);

    _isServiceStarted = true;
  }

  log.Level _getLogLevelForModule(log.LogRecord rec) {
    if (_logLevelsPerLogger.containsKey(rec.loggerName)) {
      return _logLevelsPerLogger[rec.loggerName];
    } else {
      return _logLevelsPerLogger[ROOT_LOG_LEVEL_KEY];
    }
  }
}
