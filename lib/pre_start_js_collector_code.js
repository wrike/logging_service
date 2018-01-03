(function () {
  "use strict";
  /**
   * @type {boolean}
   */
  window.loggingServiceIsJsPreStartErrorSavingEnabled = true;
  /**
   * @type {Array<ErrorEvent>}
   */
  window.loggingServiceJsPreStartErrorsList = [];

  window.addEventListener('error',
    /**
     * @param e {ErrorEvent}
     */
    function (e) {
      if (loggingServiceIsJsPreStartErrorSavingEnabled) {
        loggingServiceJsPreStartErrorsList.push(e);
      }
    }
  );
})();
