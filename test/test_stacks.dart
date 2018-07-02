const String testStack = r'''
TestExceptionType:
    at Object.wrapException (http://localhost:8080/integration/configure_logging_for_browser_test.dart.js:2776:17)
    at StaticClosure.dart.main (http://localhost:8080/integration/configure_logging_for_browser_test.dart.js:9973:15)
    at _IsolateContext.eval$1 (http://localhost:8080/integration/configure_logging_for_browser_test.dart.js:1905:25)
    at Object.startRootIsolate (http://localhost:8080/integration/configure_logging_for_browser_test.dart.js:1618:21)
    at http://localhost:8080/integration/configure_logging_for_browser_test.dart.js:10729:11
    at http://localhost:8080/integration/configure_logging_for_browser_test.dart.js:10730:9
    at http://localhost:8080/integration/configure_logging_for_browser_test.dart.js:10710:7
    at http://localhost:8080/integration/configure_logging_for_browser_test.dart.js:10721:5
    at http://localhost:8080/integration/configure_logging_for_browser_test.dart.js:10733:3
  ''';

const List<String> testStacks = const [
  r'''
dart:core                                                      Object.noSuchMethod
package:my_package/component/app_component.dart 111:1          AppComponent.ngAfterViewInit.<fn>
dart:async                                                     _ZoneDelegate.runUnary
package:angular/src/core/zone/ng_zone.dart 185:21              NgZone._runUnary
dart:async                                                     _ZoneDelegate.run
package:angular/src/core/zone/ng_zone.dart 175:21              NgZone._run
dart:async                                                     _CustomZone.bindCallback.<fn>
package:angular/src/core/zone/ng_zone.dart 234:11              NgZone._createTimer.<fn>
dart:async                                                     _ZoneDelegate.run
package:angular/src/core/zone/ng_zone.dart 175:21              NgZone._run
''',
  r'''
dart:async                                                     _Future.then
package:my_package/component/app_component.dart 181:60           AppComponent.ngAfterViewInit
package:my_package/component/app_component.template.dart 762:26  _ViewAppComponentHost0.detectChangesInternal
package:angular/src/core/linker/app_view.dart 369:7            AppView.detectChanges
package:angular/src/core/linker/view_ref.dart 103:13           ViewRefImpl.detectChanges
package:angular/src/core/application_ref.dart 440:30           ApplicationRefImpl._runTick
package:angular/src/core/application_ref.dart 420:7            ApplicationRefImpl.tick
package:angular/src/core/application_ref.dart 383:5            ApplicationRefImpl._loadComponent
package:angular/src/core/application_ref.dart 376:7            ApplicationRefImpl.bootstrap.<fn>
package:angular/src/core/application_ref.dart 318:26           ApplicationRefImpl.run.<fn>
dart:async                                                     _ZoneDelegate.run
package:angular/src/core/zone/ng_zone.dart 175:21              NgZone._run
dart:async                                                     _CustomZone.run
package:angular/src/core/zone/ng_zone.dart 305:23              NgZone.run
package:angular/src/core/application_ref.dart 316:10           ApplicationRefImpl.run
package:angular/src/core/application_ref.dart 345:12           ApplicationRefImpl.bootstrap
package:angular/src/core/application_ref.dart 91:19            coreLoadAndBootstrap.<fn>
''',
  r'''
dart:async                                                     _asyncThenWrapperHelper
package:angular/src/core/application_ref.dart 86:36            coreLoadAndBootstrap.<fn>
package:angular/src/core/application_ref.dart 318:26           ApplicationRefImpl.run.<fn>
dart:async                                                     _ZoneDelegate.run
package:angular/src/core/zone/ng_zone.dart 175:21              NgZone._run
dart:async                                                     _CustomZone.run
package:angular/src/core/zone/ng_zone.dart 305:23              NgZone.run
package:angular/src/core/application_ref.dart 316:10           ApplicationRefImpl.run
package:angular/src/core/application_ref.dart 86:23            coreLoadAndBootstrap
    '''
];
