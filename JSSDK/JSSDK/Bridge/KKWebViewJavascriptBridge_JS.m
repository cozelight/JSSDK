// This file contains the source for the Javascript side of the
// KKWebViewJavascriptBridge. It is plaintext, but converted to an NSString
// via some preprocessor tricks.
//
// Previous implementations of KKWebViewJavascriptBridge loaded the javascript source
// from a resource. This worked fine for app developers, but library developers who
// included the bridge into their library, awkwardly had to ask consumers of their
// library to include the resource, violating their encapsulation. By including the
// Javascript as a string resource, the encapsulation of the library is maintained.

#import "KKWebViewJavascriptBridge_JS.h"

NSString * KKWebViewJavascriptBridge_js() {
	#define __wvjb_js_func__(x) #x
	
	// BEGIN preprocessorJSCode
	static NSString * preprocessorJSCode = @__wvjb_js_func__(
;(function() {
	if (window.WebViewJavascriptBridge) {
		return;
	}
	window.WebViewJavascriptBridge = {
		registerHandler: registerHandler,
		callHandler: callHandler,
		_handleMessageFromObjC: _handleMessageFromObjC
	};

	var messageHandlers = {};
	var responseCallbacks = {};
	var uniqueId = 1;
    
    var CUSTOM_POST_NAME = 'ccwork_bridge';
    var _messageHandlers = window.webkit.messageHandlers;

	function registerHandler(handlerName, handler) {
		messageHandlers[handlerName] = handler;
	}
	
	function callHandler(handlerName, data, responseCallback) {
		_doSend({ handlerName:handlerName, data:data }, responseCallback);
	}
	
	function _doSend(message, responseCallback) {
		if (responseCallback) {
			var callbackId = 'cb_'+(uniqueId++)+'_'+new Date().getTime();
			responseCallbacks[callbackId] = responseCallback;
			message['callbackId'] = callbackId;
		}
        var messageString = JSON.stringify(message);
		_messageHandlers[CUSTOM_POST_NAME].postMessage(messageString);
	}

	function _dispatchMessageFromObjC(messageJSON) {
		setTimeout(function _timeoutDispatchMessageFromObjC() {
			var message = JSON.parse(messageJSON);
			var messageHandler;
			var responseCallback;

			if (message.responseId) {
				responseCallback = responseCallbacks[message.responseId];
				if (!responseCallback) {
					return;
				}
				responseCallback(message.responseData);
				delete responseCallbacks[message.responseId];
			} else {
				if (message.callbackId) {
					var callbackResponseId = message.callbackId;
					responseCallback = function(responseData) {
						_doSend({ responseId:callbackResponseId, responseData:responseData });
					};
				}
				
				var handler = messageHandlers[message.handlerName];
				try {
					handler(message.data, responseCallback);
				} catch(exception) {
					console.log("KKWebViewJavascriptBridge: WARNING: javascript handler threw.", message, exception);
				}
				if (!handler) {
					console.log("KKWebViewJavascriptBridge: WARNING: no handler for message from ObjC:", message);
				}
			}
		});
	}
	
	function _handleMessageFromObjC(messageJSON) {
        _dispatchMessageFromObjC(messageJSON);
	}

	setTimeout(_callWVJBCallbacks, 0);
	function _callWVJBCallbacks() {
		var callbacks = window.WVJBCallbacks;
		delete window.WVJBCallbacks;
		for (var i=0; i<callbacks.length; i++) {
			callbacks[i](WebViewJavascriptBridge);
		}
	}
})();
	); // END preprocessorJSCode

	#undef __wvjb_js_func__
	return preprocessorJSCode;
};
