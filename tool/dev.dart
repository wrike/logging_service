library tool.dev;

import 'dart:async';

import 'package:dart_dev/dart_dev.dart' show dev, config;

/// https://github.com/Workiva/dart_dev
Future main(List<String> args) async {
  var dirs = ['lib/', 'tool/', 'test/'];

  config.format
    ..paths = dirs
    ..lineLength = 120;

  config.coverage
    ..html = false
    ..reportOn = const ['lib/']
    ..pubServe = true;

  config.analyze
    ..fatalWarnings = true
    ..hints = true
    ..fatalHints = true
    ..strong = true
    ..fatalLints = true
    ..entryPoints = dirs;

  config.test
    ..concurrency = 1
    ..platforms = ['dartium']
    ..pubServePort = 8787
    ..pubServe = true;

  await dev(args);
}
