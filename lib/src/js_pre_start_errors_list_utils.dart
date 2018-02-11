@JS()
library configure_logging_for_browser;

import 'package:js/js.dart';
import 'package:logging_service/src/js_utils.dart';

@JS('loggingServiceIsJsPreStartErrorSavingEnabled')
external bool get loggingServiceIsJsPreStartErrorSavingEnabled;
@JS('loggingServiceIsJsPreStartErrorSavingEnabled')
external set loggingServiceIsJsPreStartErrorSavingEnabled(bool value);

@JS('loggingServiceJsPreStartErrorsList')
external List<JsErrorEvent> get loggingServiceJsPreStartErrorsList;
@JS('loggingServiceJsPreStartErrorsList')
external set loggingServiceJsPreStartErrorsList(List<JsErrorEvent> value);
