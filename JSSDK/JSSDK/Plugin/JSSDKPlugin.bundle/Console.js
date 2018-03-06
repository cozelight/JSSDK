console = {
  log: function (string) {
    window.webkit.messageHandlers.ccwork_plugin.postMessage({className: 'Console', functionName: 'log', data: string});
  }
}
