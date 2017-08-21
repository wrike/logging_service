import 'dart:html' as html;

import 'package:sentry_client/api_data/sentry_packet.dart';
import 'package:sentry_client/api_data/sentry_request.dart';

class SentryPreSaveForBrowser {
  void call(SentryPacket packet) {
    packet.culprit = Uri.base.toString();
    packet.serverName = Uri.base.host;
    packet.request = new SentryRequest(
        headers: {SentryRequest.userAgentHeaderKey: html.window.navigator.userAgent}, url: Uri.base.toString());

    html.window.console.error('The sentry accident id: ${packet.eventId}');
  }
}
