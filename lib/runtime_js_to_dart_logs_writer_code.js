(function () {
  "use strict";

  window.loggingServiceOriginalConsoleMethods = {};
  window.loggingServiceOriginalConsoleMethods.error = window.console.error.bind(console);
  window.loggingServiceOriginalConsoleMethods.info = window.console.info.bind(console);
  window.loggingServiceOriginalConsoleMethods.log = window.console.log.bind(console);

  window.loggingServiceLogWriteBuffer = [];
  window.loggingServiceJsToDartLogsWriter = null;

  /**
   * @param level {String} <error>/<info>/<log>
   * @private
   */
  function _handleWriting(level) {
    var args = Array.prototype.slice.call(arguments);

    if (window.loggingServiceJsToDartLogsWriter == null) {
      window.loggingServiceLogWriteBuffer.push(args);
    } else {
      window.loggingServiceJsToDartLogsWriter(args);
    }
  }

  window.console.error = _handleWriting.bind(window.console, 'error');
  window.console.info = _handleWriting.bind(window.console, 'info');
  window.console.log = _handleWriting.bind(window.console, 'log');
})();
