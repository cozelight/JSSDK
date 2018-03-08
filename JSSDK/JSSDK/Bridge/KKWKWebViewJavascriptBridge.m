//
//  KKWKWebViewJavascriptBridge.m
//
//  Created by @LokiMeyburg on 10/15/14.
//  Copyright (c) 2014 @LokiMeyburg. All rights reserved.
//


#import "KKWKWebViewJavascriptBridge.h"
#import "KKWebViewJSPluginBase.h"
#import "KKWebViewJavascriptBridgeBase.h"

#if defined(supportsWKWebKit)

@interface KKWKWebViewJavascriptBridge ()<KKWebViewJavascriptBridgeBaseDelegate>

@end

@implementation KKWKWebViewJavascriptBridge {
    __weak WKWebView* _webView;
    __weak id<WKNavigationDelegate> _webViewDelegate;
    long _uniqueId;
    KKWebViewJavascriptBridgeBase *_base;
}

/* API
 *****/

+ (void)enableLogging { [KKWebViewJavascriptBridgeBase enableLogging]; }

+ (instancetype)bridgeForWebView:(WKWebView*)webView {
    KKWKWebViewJavascriptBridge* bridge = [[self alloc] init];
    [bridge _setupInstance:webView];
    [bridge reset];
    return bridge;
}

- (void)send:(id)data {
    [self send:data responseCallback:nil];
}

- (void)send:(id)data responseCallback:(WVJBResponseCallback)responseCallback {
    [_base sendData:data responseCallback:responseCallback handlerName:nil];
}

- (void)callHandler:(NSString *)handlerName {
    [self callHandler:handlerName data:nil responseCallback:nil];
}

- (void)callHandler:(NSString *)handlerName data:(id)data {
    [self callHandler:handlerName data:data responseCallback:nil];
}

- (void)callHandler:(NSString *)handlerName data:(id)data responseCallback:(WVJBResponseCallback)responseCallback {
    [_base sendData:data responseCallback:responseCallback handlerName:handlerName];
}

- (void)registerHandler:(NSString *)handlerName handler:(WVJBHandler)handler {
    _base.messageHandlers[handlerName] = [handler copy];
}

- (void)reset {
    [_base reset];
}

- (void)setWebViewDelegate:(id<WKNavigationDelegate>)webViewDelegate {
    _webViewDelegate = webViewDelegate;
}

/* Internals
 ***********/

- (void)dealloc {
    [_configuration.userContentController removeScriptMessageHandlerForName:kCustomJSBridgeName];
    [_configuration.userContentController removeScriptMessageHandlerForName:kCustomJSPluginName];
    _base.delegate = nil;
    _base.startupMessageQueue = nil;
    _base.responseCallbacks = nil;
    _base.messageHandlers = nil;
    _base = nil;
    _webView = nil;
    _configuration = nil;
    _webViewDelegate = nil;
    _webView.navigationDelegate = nil;
}


/* WKWebView Specific Internals
 ******************************/

- (void)_setupInstance:(WKWebView*)webView {
    _webView = webView;
    _configuration = webView.configuration;
    _webView.navigationDelegate = self;
    _base = [[KKWebViewJavascriptBridgeBase alloc] init];
    _base.delegate = self;
    [_configuration.userContentController addScriptMessageHandler:self name:kCustomJSBridgeName];
    [_configuration.userContentController addScriptMessageHandler:self name:kCustomJSPluginName];
    
    if (@available(iOS 9.0, *)) {
        @try {
            [_configuration.preferences setValue:@TRUE forKey:@"allowFileAccessFromFileURLs"];
        }
        @catch (NSException *exception) {}
        
        @try {
            [_configuration setValue:@TRUE forKey:@"allowUniversalAccessFromFileURLs"];
        }
        @catch (NSException *exception) {}
    }
}


- (void)webView:(WKWebView *)webView didFinishNavigation:(WKNavigation *)navigation
{
    if (webView != _webView) { return; }
    
    __strong typeof(_webViewDelegate) strongDelegate = _webViewDelegate;
    if (strongDelegate && [strongDelegate respondsToSelector:@selector(webView:didFinishNavigation:)]) {
        [strongDelegate webView:webView didFinishNavigation:navigation];
    }
}


- (void)webView:(WKWebView *)webView
decidePolicyForNavigationAction:(WKNavigationAction *)navigationAction
decisionHandler:(void (^)(WKNavigationActionPolicy))decisionHandler {
    if (webView != _webView) { return; }
    NSURL *url = navigationAction.request.URL;
    __strong typeof(_webViewDelegate) strongDelegate = _webViewDelegate;

    if ([_base isCorrectProcotocolScheme:url]) {
        if ([_base isBridgeLoadedURL:url]) {
            [self _runPluginJS:self.pluginList];
            [_base injectJavascriptFile];
        } else {
            [_base logUnkownMessage:url];
        }
        decisionHandler(WKNavigationActionPolicyCancel);
        return;
    }
    
    if (strongDelegate && [strongDelegate respondsToSelector:@selector(webView:decidePolicyForNavigationAction:decisionHandler:)]) {
        [_webViewDelegate webView:webView decidePolicyForNavigationAction:navigationAction decisionHandler:decisionHandler];
    } else {
        decisionHandler(WKNavigationActionPolicyAllow);
    }
}

- (void)webView:(WKWebView *)webView didStartProvisionalNavigation:(WKNavigation *)navigation {
    if (webView != _webView) { return; }
    
    __strong typeof(_webViewDelegate) strongDelegate = _webViewDelegate;
    if (strongDelegate && [strongDelegate respondsToSelector:@selector(webView:didStartProvisionalNavigation:)]) {
        [strongDelegate webView:webView didStartProvisionalNavigation:navigation];
    }
}


- (void)webView:(WKWebView *)webView
didFailNavigation:(WKNavigation *)navigation
      withError:(NSError *)error {
    if (webView != _webView) { return; }
    
    __strong typeof(_webViewDelegate) strongDelegate = _webViewDelegate;
    if (strongDelegate && [strongDelegate respondsToSelector:@selector(webView:didFailNavigation:withError:)]) {
        [strongDelegate webView:webView didFailNavigation:navigation withError:error];
    }
}

- (void)webView:(WKWebView *)webView didReceiveAuthenticationChallenge:(NSURLAuthenticationChallenge *)challenge completionHandler:(void (^)(NSURLSessionAuthChallengeDisposition, NSURLCredential *))completionHandler {
    if (webView != _webView) { return; }
    
    __strong typeof(_webViewDelegate) strongDelegate = _webViewDelegate;
    if (strongDelegate && [strongDelegate respondsToSelector:@selector(webView:didReceiveAuthenticationChallenge:completionHandler:)]) {
        [strongDelegate webView:webView didReceiveAuthenticationChallenge:challenge completionHandler:completionHandler];
    } else {
        completionHandler(NSURLSessionAuthChallengePerformDefaultHandling, nil);
    }
}

- (void)webView:(WKWebView *)webView didFailProvisionalNavigation:(WKNavigation *)navigation withError:(NSError *)error {
    if (webView != _webView) { return; }
    
    __strong typeof(_webViewDelegate) strongDelegate = _webViewDelegate;
    if (strongDelegate && [strongDelegate respondsToSelector:@selector(webView:didFailProvisionalNavigation:withError:)]) {
        [strongDelegate webView:webView didFailProvisionalNavigation:navigation withError:error];
    }
}

- (NSString *)_evaluateJavascript:(NSString*)javascriptCommand
{
    [_webView evaluateJavaScript:javascriptCommand completionHandler:nil];
    return NULL;
}

- (void)userContentController:(WKUserContentController *)userContentController didReceiveScriptMessage:(WKScriptMessage *)message {
    if ([message.name isEqualToString:kCustomJSBridgeName]) {
        [_base flushMessageQueue:[message.body description]];
    } else if ([message.name isEqualToString:kCustomJSPluginName]) {
        [self reflectionPluginJS:message];
    }
}

#pragma mark - Plugin JS

- (void)_runPluginJS:(NSArray <__kindof NSString *> *)pluginJS {
    [pluginJS enumerateObjectsUsingBlock:^(__kindof NSString * _Nonnull obj, NSUInteger idx, BOOL * _Nonnull stop) {
        NSString *path = [[self pluginBundle] pathForResource:obj ofType:@"js"];
        NSError *error;
        NSString *js = [NSString stringWithContentsOfFile:path encoding:NSUTF8StringEncoding error:&error];
        if (error) {
            NSLog(@"%s, js instance error =%@",__func__, error.debugDescription);
        } else {
            [_webView evaluateJavaScript:js completionHandler:nil];
        }
    }];
}

- (void)reflectionPluginJS:(WKScriptMessage *)message {
    NSDictionary *dict = message.body;
    if ([dict isKindOfClass:[NSDictionary class]]) {
        NSString *className = dict[@"className"];
        NSString *functionName = dict[@"functionName"];
        if (className && functionName) {
            Class cls = NSClassFromString(className);
            if ([cls isSubclassOfClass:[KKWebViewJSPluginBase class]]) {
                KKWebViewJSPluginBase *obj = [[cls alloc] init];
                SEL functionSelector = NSSelectorFromString(functionName);
                if ([obj respondsToSelector:functionSelector]) {
                    obj.webView = _webView;
                    obj.taskId = [dict[@"taskId"] unsignedIntegerValue];
                    obj.data = dict[@"data"];
#pragma clang diagnostic push
#pragma clang diagnostic ignored "-Warc-performSelector-leaks"
                    [obj performSelector:functionSelector];
#pragma clang diagnostic pop
                } else {
                    NSLog(@"Reflection Failure! Not found %@ in %@",functionName, className);
                }
            } else {
                NSLog(@"Reflection Failure! Class %@ not found", className);
            }
        } else {
            NSLog(@"Reflection Failure! Data error: %@", [message.body description]);
        }
    } else {
        NSLog(@"Reflection Failure! Data error: %@", [message.body description]);
    }
}

- (NSBundle *)pluginBundle {
    static NSBundle *pluginBundle = nil;
    if (pluginBundle == nil) {
        NSBundle *jsBundle = [NSBundle bundleForClass:[KKWebViewJSPluginBase class]];
        pluginBundle = [NSBundle bundleWithPath:[jsBundle pathForResource:@"JSSDKPlugin" ofType:@"bundle"]];
        NSAssert(pluginBundle != nil, @"");
    }
    return pluginBundle;
}

@end


#endif
