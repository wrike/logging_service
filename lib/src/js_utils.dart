@JS()
library js_utils;

import 'dart:convert';

import 'package:js/js.dart';

bool isItJsObject(dynamic obj) => jsonStringify(obj).startsWith('{');

dynamic jsify(Object o) => jsonParse(JSON.encode(o));

@JS('JSON.parse')
external dynamic jsonParse(String json);

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
