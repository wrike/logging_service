import 'dart:html' as html;

import 'package:logging_service/src/js_console_proxy.dart';
import 'package:sentry_client/api_data/sentry_packet.dart';
import 'package:sentry_client/api_data/sentry_request.dart';

class SentryPreSaveForBrowser {
  final JsConsoleProxy _consoleProxy;

  SentryPreSaveForBrowser({JsConsoleProxy consoleProxy}) : _consoleProxy = consoleProxy ?? new JsConsoleProxy();

  void call(SentryPacket packet) {
    packet.culprit = Uri.base.toString();
    packet.serverName = Uri.base.host;
    packet.request = new SentryRequest(
        headers: {SentryRequest.userAgentHeaderKey: html.window.navigator.userAgent}, url: Uri.base.toString());

    _consoleProxy.error('The sentry accident id: ${packet.eventId}');
  }
}
