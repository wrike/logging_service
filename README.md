[![pub](https://img.shields.io/pub/v/logging_service.svg)](https://pub.dartlang.org/packages/logging_service)
[![Build Status](https://travis-ci.org/wrike/logging_service.svg?branch=master)](https://travis-ci.org/wrike/logging_service)
[![codecov](https://codecov.io/gh/wrike/logging_service/branch/master/graph/badge.svg)](https://codecov.io/gh/wrike/logging_service)
[![documentation](https://img.shields.io/badge/Documentation-logging_service-blue.svg)](https://www.dartdocs.org/documentation/logging_service/latest)

### The service for advanced work with logging

#### Motivation:
You start using [logging](https://pub.dartlang.org/packages/logging) package. 
You are able to change log-level for the **whole application only**.
Or you should set **log level manually** for every new `Logger` instance **inside the code**.
It is not very convenient.  
We wanted to change log-levels **per module**, and change log-levels per module and for the whole app **in runtime**.
With this library you will be able to do it, even a little bit more - read below.

#### The fast start example:

```dart
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
  logger2.severe('Some error! We should fix it!')
  logger2.shout('Some dev-message')
});
```

#### What do you get as a result (each feature can be disabled by configuration):

1. You can manage log level per module:  
By code: `LoggingService.setLogLevelPerLogger(String loggerName, log.Level level)`  
In runtime by adding the hash parameter to your app-url: `#logging={"myModuleName": "SEVERE"}`
`myModuleName` should be the name that you used when you created `new Logger('myModuleName');`  

By default you will see in the browser console only `Level.SEVERE` and higher levels of messages.
But if you want to change it you can manage the base level for the whole application:  
By code: `LoggingService.setLogLevelPerLogger(LoggingService.ROOT_LOG_LEVEL_KEY, log.Level level)`    
or to set it with the call of: `loggingService.start(rootLogLevel: Level.INFO)`  
In runtime by adding the hash parameter to your app-url: `#logging={"rootLogLevel": "INFO"}`  

2. You `SEVERE` messages are being saved to the sentry server:
If you put the `appVersionUid` and `sentryDsn` arguments to the `ConfigureLoggingForBrowser.setUpAll()` call.  
Or if you configured saver manually `loggingService.addLoggingSavers([new LoggingSaverForSentry(...)]);`  
You can change the level for what message is being sent to the savers by changing the `savableLogLevel` arg for the 
`loggingService.start(savableLogLevel: Level.SEVERE)` call.

3. The default printer is printing messages and exceptions in accordance with your levels-settings. 
It prints exceptions in a way that allows the browser to use source-maps and 
show you source-code links if you had connected the source-map file.  

4. The exceptions inside the `loggingService.runProtected()` call will be captured and chained by default.  
It means that you will see the whole sequence of calls (and their stack-traces) that led to the error.  
_Yes, I now that there are some fears that chaining is slow. 
But you will see it only if you use long nested sequences of call. Very long, like 100-1000 levels. 
If the size of you sequence is something like 4-10 as usual - 
the chaining of stack-traces is not your bottleneck, even not a problem. We checked it for us and use it in production._ 

5. The system listens js-errors (through `window.onError`) and handles them.

6. The system can collect even js-errors that had happened before the dart-code started:  
To do this you should put js-code-snippet from the [lib/pre_start_js_collector_code.js](lib/pre_start_js_collector_code.js) 
to the very beginning of your scripts. 

7. If you want to collect errors from the dart-angular you should use something like this:

```dart
import 'package:angular2/di.dart';
import 'package:logging/logging.dart' as log;
import 'package:logging_service/logging_service.dart';
import 'package:stack_trace/stack_trace.dart';

class AppExceptionHandler implements ExceptionHandler {
  final LoggingService _loggingService;

  AppExceptionHandler(loggingService) : this._loggingService = loggingService;

  @override
  void call(dynamic error, [dynamic stackTrace, String reason]) {
        if (stackTrace is Iterable) {
          stackTrace = new Chain((stackTrace as Iterable).map((dynamic trace) => new Trace.parse(trace.toString())));
        } else {
          stackTrace = new Trace.parse(stackTrace.toString());
        }

        _loggingService.handleLogRecord(
          new log.LogRecord(
            log.Level.SEVERE,
            reason,
            'ngErrorLogger',
            error,
            stackTrace as StackTrace,
          ),
        );
  }
}
```

and then put the provider for `ExceptionHandler` to your `bootstrap` call:
 
```dart
bootstrap(AppComponent, [new Provider(ExceptionHandler, useValue: new AppExceptionHandler(loggingService))]);
```
