//
//  KKWKWebViewJavascriptBridge.h
//
//  Created by @LokiMeyburg on 10/15/14.
//  Copyright (c) 2014 @LokiMeyburg. All rights reserved.
//

#if (__MAC_OS_X_VERSION_MAX_ALLOWED > __MAC_10_9 || __IPHONE_OS_VERSION_MAX_ALLOWED >= __IPHONE_7_1)
#define supportsWKWebKit
#endif

#if defined(supportsWKWebKit)

#import <Foundation/Foundation.h>
#import <WebKit/WebKit.h>

#define kCustomJSPluginName @"ccwork_plugin"

typedef void (^WVJBResponseCallback)(id responseData);
typedef void (^WVJBHandler)(id data, WVJBResponseCallback responseCallback);

@interface KKWKWebViewJavascriptBridge : NSObject<WKNavigationDelegate,WKScriptMessageHandler>

/// 需要安装的插件列表
@property (nonatomic, copy) NSArray<__kindof NSString *> *pluginList;

+ (instancetype)bridgeForWebView:(WKWebView*)webView;
+ (void)enableLogging;

- (void)registerHandler:(NSString*)handlerName handler:(WVJBHandler)handler;
- (void)callHandler:(NSString*)handlerName;
- (void)callHandler:(NSString*)handlerName data:(id)data;
- (void)callHandler:(NSString*)handlerName data:(id)data responseCallback:(WVJBResponseCallback)responseCallback;
- (void)reset;
- (void)setWebViewDelegate:(id<WKNavigationDelegate>)webViewDelegate;

@end

#endif
