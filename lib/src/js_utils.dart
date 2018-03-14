@JS()
library js_utils;

import 'package:js/js.dart';

//TODO: remove (it does not work)
bool isItJsObject(dynamic obj) => jsonStringify(obj).startsWith('{');

@JS('JSON.stringify')
external String jsonStringify(dynamic obj);

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
