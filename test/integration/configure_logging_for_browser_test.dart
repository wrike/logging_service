@TestOn('browser')
import 'dart:async';
import 'dart:html' as html;
import 'dart:html_common' as html_common;

import 'package:logging/logging.dart' as log;
import 'package:logging_service/configure_logging_for_browser.dart';
import 'package:logging_service/logging_service.dart';
import 'package:mockito/mockito.dart';
import 'package:test/test.dart';

import '../test_stacks.dart';

void main() {
  group('listenJsErrors should', () {
    LoggingServiceMock loggingServiceMock;
    StreamController<html.Event> onErrorStreamController;
    WindowMock windowMock;

    setUp(() {
      loggingServiceMock = new LoggingServiceMock();
      onErrorStreamController = new StreamController<html.Event>.broadcast(sync: true);

      windowMock = new WindowMock();
      when(windowMock.onError).thenAnswer((_) => onErrorStreamController.stream);
      ConfigureLoggingForBrowser.listenJsErrors(loggingServiceMock, window: windowMock, handleGlobalJsErrors: true);
    });

    test('get the message from the error-event if it has the message field', () {
      var errorMock = new html.ErrorEvent('testType', <dynamic, dynamic>{'message': 'testMsg'});

      onErrorStreamController.add(errorMock);

      var rec = verify(loggingServiceMock.handleLogRecord(captureAny)).captured.first as log.LogRecord;
      expect(rec.message, 'testMsg');
    });

    test('asseble error-data from the error event', () {
      var errorMock = new html.ErrorEvent('testType', <dynamic, dynamic>{
        'message': 'testMsg',
        'filename': 'test/file/name',
        'lineno': 23,
        'type': 'SomeTestType',
        'timeStamp': 1231,
      });

      onErrorStreamController.add(errorMock);

      var rec = verify(loggingServiceMock.handleLogRecord(captureAny)).captured.first as log.LogRecord;
      expect(rec.error, new TypeMatcher<Map>());
      expect((rec.error as Map).isNotEmpty, true);
    });

    test('not faile if the errorEvent.error is not a JsError', () {
      var errorMock = new html.ErrorEvent('testType', <dynamic, dynamic>{
        'message': 'testMsg',
        'error': new Object(),
      });

      onErrorStreamController.add(errorMock);

      verify(loggingServiceMock.handleLogRecord(captureAny)).called(1);
    });

    test('aggregate info from the nested error message if it is additional info', () {
      var errorMock = new html.ErrorEvent('testType', <dynamic, dynamic>{
        'message': 'testMsg',
        'error': html_common.convertDartToNative_Dictionary(<dynamic, dynamic>{
          'message': 'additional testMsg',
        }),
      });

      onErrorStreamController.add(errorMock);

      var rec = verify(loggingServiceMock.handleLogRecord(captureAny)).captured.first as log.LogRecord;
      expect(rec.message, contains('additional testMsg'));
    });

    test('not aggregate info from the nested error message if it does not contain addtional info', () {
      var errorMock = new html.ErrorEvent('testType', <dynamic, dynamic>{
        'message': 'Msg: testMsg',
        'error': html_common.convertDartToNative_Dictionary(<dynamic, dynamic>{
          'message': 'testMsg',
        }),
      });

      onErrorStreamController.add(errorMock);

      var rec = verify(loggingServiceMock.handleLogRecord(captureAny)).captured.first as log.LogRecord;
      expect('testMsg'.allMatches(rec.message).toList().length, 1);
    });

    test('get the stack-trace from the nested error object if it exists', () {
      var errorMock = new html.ErrorEvent(
        'testType',
        <dynamic, dynamic>{
          'message': 'testMsg',
          'error': html_common.convertDartToNative_Dictionary(<dynamic, dynamic>{
            'stack': testStack,
          }),
        },
      );

      onErrorStreamController.add(errorMock);

      var rec = verify(loggingServiceMock.handleLogRecord(captureAny)).captured.first as log.LogRecord;
      expect(rec.stackTrace.toString(), testStack);
    });

    test('get the message from the the nested error object if there is no message at the first level', () {
      var errorMock = new html.ErrorEvent(
        'testType',
        <dynamic, dynamic>{
          'error': html_common.convertDartToNative_Dictionary(<dynamic, dynamic>{
            'stack': testStack,
            'message': 'nestedTestMsg',
          }),
        },
      );

      onErrorStreamController.add(errorMock);

      var rec = verify(loggingServiceMock.handleLogRecord(captureAny)).captured.first as log.LogRecord;
      expect(rec.message, 'nestedTestMsg');
    });

    test('log message even if an error-event has an incorrect type', () {
      onErrorStreamController.add(null);

      verify(loggingServiceMock.handleLogRecord(captureAny)).called(1);
    });
  });

  group('setLogLevelsFromUrl should', () {
    WindowMock windowMock;
    LocationMock location;
    LoggingServiceMock loggingServiceMock;

    setUp(() {
      windowMock = new WindowMock();
      location = new LocationMock();
      loggingServiceMock = new LoggingServiceMock();

      when(windowMock.location).thenReturn(location);
    });

    test('set level for single logger', () {
      when(location.hash).thenReturn('#logging={"logger": "INFO"}');

      ConfigureLoggingForBrowser.setLogLevelsFromUrl(loggingServiceMock, window: windowMock);

      verify(loggingServiceMock.setLogLevelPerLogger('logger', log.Level.INFO));
      verifyNoMoreInteractions(loggingServiceMock);
    });

    test('set levels for several loggers', () {
      when(location.hash).thenReturn('#logging={"logger": "INFO", "logger2": "WARNING"}');

      ConfigureLoggingForBrowser.setLogLevelsFromUrl(loggingServiceMock, window: windowMock);

      verify(loggingServiceMock.setLogLevelPerLogger('logger', log.Level.INFO));
      verify(loggingServiceMock.setLogLevelPerLogger('logger2', log.Level.WARNING));
      verifyNoMoreInteractions(loggingServiceMock);
    });

    test('skip loggers with unknown levels', () {
      when(location.hash).thenReturn('#logging={"logger": "INFO", "logger2": "UNKNOWN"}');

      ConfigureLoggingForBrowser.setLogLevelsFromUrl(loggingServiceMock, window: windowMock);

      verify(loggingServiceMock.setLogLevelPerLogger('logger', log.Level.INFO));
      verifyNoMoreInteractions(loggingServiceMock);
    });

    test('extract logger configuration from hash with multiple params', () {
      when(location.hash).thenReturn('#some_param=some_value&logging={"logger": "INFO"}');

      ConfigureLoggingForBrowser.setLogLevelsFromUrl(loggingServiceMock, window: windowMock);

      verify(loggingServiceMock.setLogLevelPerLogger('logger', log.Level.INFO));
      verifyNoMoreInteractions(loggingServiceMock);
    });
  });
}

class LoggingServiceMock extends Mock implements LoggingService {}

//ignore: mismatched_getter_and_setter_types
class WindowMock extends Mock implements html.Window {}

class LocationMock extends Mock implements html.Location {}
