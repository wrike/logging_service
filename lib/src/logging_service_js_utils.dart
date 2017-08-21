@JS()
library configure_logging_for_browser;

import 'package:js/js.dart';

@JS('loggingServiceIsJsPreStartErrorSavingEnabled')
external bool get loggingServiceIsJsPreStartErrorSavingEnabled;
@JS('loggingServiceIsJsPreStartErrorSavingEnabled')
external set loggingServiceIsJsPreStartErrorSavingEnabled(bool value);

@JS('loggingServiceJsPreStartErrorsList')
external List<JsErrorEvent> get loggingServiceJsPreStartErrorsList;
@JS('loggingServiceJsPreStartErrorsList')
external set loggingServiceJsPreStartErrorsList(List<JsErrorEvent> value);

@JS()
@anonymous
class JsError {
  external String get message;
  external String get stack;
}

@JS()
@anonymous
class JsErrorEvent {
  external JsError get error;
  external String get message;
}
