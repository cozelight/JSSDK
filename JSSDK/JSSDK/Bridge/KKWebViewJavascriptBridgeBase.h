//
//  KKWebViewJavascriptBridgeBase.h
//
//  Created by @LokiMeyburg on 10/15/14.
//  Copyright (c) 2014 @LokiMeyburg. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "KKWKWebViewJavascriptBridge.h"

#define kCustomProtocolScheme @"wvjbscheme"
#define kBridgeLoaded         @"__BRIDGE_LOADED__"

typedef NSDictionary WVJBMessage;

@protocol KKWebViewJavascriptBridgeBaseDelegate <NSObject>
- (NSString*)_evaluateJavascript:(NSString*)javascriptCommand;
@end

@interface KKWebViewJavascriptBridgeBase : NSObject


@property (assign) id <KKWebViewJavascriptBridgeBaseDelegate> delegate;
@property (strong, nonatomic) NSMutableArray* startupMessageQueue;
@property (strong, nonatomic) NSMutableDictionary* responseCallbacks;
@property (strong, nonatomic) NSMutableDictionary* messageHandlers;
@property (strong, nonatomic) WVJBHandler messageHandler;

+ (void)enableLogging;
+ (void)setLogMaxLength:(int)length;
- (void)reset;
- (void)sendData:(id)data responseCallback:(WVJBResponseCallback)responseCallback handlerName:(NSString*)handlerName;
- (void)flushMessageQueue:(NSString *)messageQueueString;
- (void)injectJavascriptFile;
- (BOOL)isCorrectProcotocolScheme:(NSURL*)url;
- (BOOL)isBridgeLoadedURL:(NSURL*)url;
- (void)logUnkownMessage:(NSURL*)url;
- (NSString *)webViewJavascriptCheckCommand;
- (NSString *)webViewJavascriptFetchQueyCommand;

@end
