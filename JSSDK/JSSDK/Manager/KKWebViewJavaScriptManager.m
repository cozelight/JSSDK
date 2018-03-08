//
//  KKWebViewJavaScriptManager.m
//  JSSDK
//
//  Created by coze on 2017/12/4.
//  Copyright © 2017年 cozelight. All rights reserved.
//

#import "KKWebViewJavaScriptManager.h"
#import "KKWebViewJSApiBase.h"

@interface KKWebViewJavaScriptManager ()

@property (nonatomic, strong) NSMutableArray *registeredApiList;

@end

@implementation KKWebViewJavaScriptManager

#pragma mark - Class methods

+ (instancetype)managerForWebView:(WKWebView *)webView containerVC:(UIViewController *)containerVC {
    KKWebViewJavaScriptManager *manager = [[self alloc] init];
    manager.webViewBridge = [KKWKWebViewJavascriptBridge bridgeForWebView:webView];
    manager.containerVC = containerVC;
    return manager;
}

+ (NSDictionary *)createSuccessResponseData:(id)data {
    NSMutableDictionary *responseDict = [NSMutableDictionary dictionary];
    responseDict[@"errcode"] = @(0);
    responseDict[@"errmsg"] = @"OK";
    if (data) {
        responseDict[@"data"] = data;
    }
    return responseDict;
}

+ (NSDictionary *)createFailureResponseDataWithErrorcode:(NSInteger)errorcode errormsg:(id)errormsg {
    NSMutableDictionary *responseDict = [NSMutableDictionary dictionary];
    if (errorcode) {
        responseDict[@"errcode"] = [@(errorcode) stringValue];
    } else {
        responseDict[@"errcode"] = @(1);
    }
    if (errormsg) {
        responseDict[@"errmsg"] = errormsg;
    } else {
        responseDict[@"errmsg"] = [NSString stringWithFormat:@"errcode = %@", @(errorcode)];
    }
    return responseDict;
}

+ (NSDictionary *)createProgressResponseData:(id)data {
    NSMutableDictionary *responseDict = [NSMutableDictionary dictionary];
    responseDict[@"errcode"] = @(-100);
    if (data) {
        responseDict[@"data"] = data;
    }
    return responseDict;
}

- (void)dealloc {
    [_webViewBridge.configuration.userContentController removeScriptMessageHandlerForName:kCustomJSBridgeName];
    [_webViewBridge.configuration.userContentController removeScriptMessageHandlerForName:kCustomJSPluginName];
    _webViewBridge.configuration = nil;
    _webViewBridge = nil;
}

#pragma mark - Public methods

- (NSArray *)getRegisteredAPIList {
    return self.registeredApiList;
}

- (void)installPluginJS:(NSArray <__kindof NSString *> *)pluginJS {
    self.webViewBridge.pluginList = pluginJS;
}

#pragma mark - Private methods

- (BOOL)_checkAPILegal:(NSString *)apiName {
    if ([self.delegate respondsToSelector:@selector(checkAPILegal:)]) {
        return [self.delegate checkAPILegal:apiName];
    }
    return YES;
}

- (void)_authenticationSignatureParameter:(NSDictionary *)parameter comlete:(void (^)(NSError *))complete {
    if ([self.delegate respondsToSelector:@selector(authenticationSignatureParameter:comlete:)]) {
        return [self.delegate authenticationSignatureParameter:parameter comlete:complete];
    } else {
        NSError *error = [NSError errorWithDomain:@"ccwork" code:1 userInfo:nil];
        complete(error);
    }
}

#pragma mark - JS Register

/**
 对于a.xx..xx.b方法，
 取最后一个点之前字符串为className，最后一个点之后字符串为functionName
 */
- (id<KKWebViewJSApiBaseProtocol>)createJSApiObj:(NSString *)jsApiName {
    
    BOOL isLegal = [self _checkAPILegal:jsApiName];
    if (!isLegal) {
        return nil;
    }
    
    NSRange lastDot = [jsApiName rangeOfString:@"." options:NSBackwardsSearch];
    NSString *functionName = [jsApiName substringFromIndex:lastDot.location + lastDot.length];
    NSString *className = [jsApiName substringToIndex:lastDot.location];
    className = [className stringByReplacingOccurrencesOfString:@"." withString:@"_"];
    
    Class cls = NSClassFromString(className);
    if ([cls conformsToProtocol:@protocol(KKWebViewJSApiBaseProtocol)]) {
        id<KKWebViewJSApiBaseProtocol> obj = [[cls alloc] init];
        if ([obj respondsToSelector:NSSelectorFromString(functionName)]) {
            obj.apiName = jsApiName; // 重写set方法，进行event，isNeedRegistId参数的设置
            obj.jsManager = self;
            __weak typeof(self) weakSelf = self;
            [self.webViewBridge registerHandler:jsApiName handler:^(id data, WVJBResponseCallback responseCallback) {
                if (!obj.isNeedRegistId) {
                    id<KKWebViewJSApiBaseProtocol> obj = [[cls alloc] init];
                    obj.apiName = jsApiName;
                    obj.jsManager = weakSelf;
                }
                obj.paramData = data;
                obj.responseCallback = responseCallback;
#pragma clang diagnostic push
#pragma clang diagnostic ignored "-Warc-performSelector-leaks"
                [obj performSelector:NSSelectorFromString(functionName)];
#pragma clang diagnostic pop
            }];
            return obj;
        } else {
            NSLog(@"function is not found");
            return nil;
        }
    } else {
        NSLog(@"clss is not found");
        return nil;
    }
}

/**
 js初始化默认方法
 cc.init({
    jsApiList : [  // 必填，无需config，即可使用的jsapi列表
        'biz.contact.choose',
        'device.notification.confirm',
        'device.notification.alert',
        'device.notification.prompt',
        'biz.util.openLink'
    ]
 });
 */
- (void)registerInit {
    __weak typeof(self) weakSelf = self;
    
    [_webViewBridge registerHandler:@"init" handler:^(NSDictionary *dict, WVJBResponseCallback responseCallback) {
        NSMutableArray *supportApiList = [NSMutableArray array];
        NSMutableArray *invalidJsApiArr = [NSMutableArray array];
        
        NSArray *jsApiList = [dict valueForKey:@"jsApiList"];
        [jsApiList enumerateObjectsUsingBlock:^(NSString *apiName, NSUInteger idx, BOOL * _Nonnull stop) {
            id<KKWebViewJSApiBaseProtocol> obj = [weakSelf createJSApiObj:apiName];
            if (!obj) {
                [invalidJsApiArr addObject:apiName];
            } else {
                NSMutableDictionary *dict = [NSMutableDictionary dictionary];
                dict[@"key"] = apiName;
                dict[@"event"] = @(obj.isEvent);
                dict[@"isNeedRegistId"] = @(obj.isNeedRegistId);
                [supportApiList addObject:dict];
            }
        }];
        NSMutableDictionary *paramDict = [NSMutableDictionary dictionaryWithDictionary:@{@"clientApiList":supportApiList}];
        if (invalidJsApiArr.count > 0) {
           [paramDict setObject:invalidJsApiArr forKey:@"nonExistentLists"];
        }
        responseCallback([KKWebViewJavaScriptManager createSuccessResponseData:paramDict]);
        
        [weakSelf.registeredApiList addObjectsFromArray:supportApiList];
    }];
}

/**
 cc.config({
    agentId: '', // 必填，微应用ID
    corpId: '',//必填，企业ID
    timeStamp: , // 必填，生成签名的时间戳
    nonceStr: '', // 必填，生成签名的随机串
    signature: '', // 必填，签名
    jsApiList : [  // 必填，需要使用的jsapi列表
        'biz.contact.choose',
        'device.notification.confirm',
        'device.notification.alert',
        'device.notification.prompt',
        'biz.ding.post',
        'biz.util.openLink'
     ]
 });
 */
- (void)registerConfig {
    __weak typeof(self) weakSelf = self;
    
    [_webViewBridge registerHandler:@"config" handler:^(NSDictionary *dict, WVJBResponseCallback responseCallback) {
        __strong typeof(self) strongSelf = weakSelf;
        
        [strongSelf _authenticationSignatureParameter:dict comlete:^(NSError *error) {
            if (error) {
                NSString *errorMsg = [NSString stringWithFormat:@"authentication failure, error:%@", error.description];
                responseCallback([KKWebViewJavaScriptManager createFailureResponseDataWithErrorcode:-1 errormsg:errorMsg]);
                return;
            }
            
            NSMutableArray *supportApiList = [NSMutableArray array];
            NSMutableArray *invalidJsApiArr = [NSMutableArray array];
            
            NSArray *jsApiList = [dict valueForKey:@"jsApiList"];
            [jsApiList enumerateObjectsUsingBlock:^(NSString *apiName, NSUInteger idx, BOOL * _Nonnull stop) {
                id<KKWebViewJSApiBaseProtocol> obj = [strongSelf createJSApiObj:apiName];
                if (!obj) {
                    [invalidJsApiArr addObject:apiName];
                } else {
                    NSMutableDictionary *dict = [NSMutableDictionary dictionary];
                    dict[@"key"] = apiName;
                    dict[@"event"] = @(obj.isEvent);
                    dict[@"isNeedRegistId"] = @(obj.isNeedRegistId);
                    [supportApiList addObject:dict];
                }
            }];
            NSMutableDictionary *paramDict = [NSMutableDictionary dictionaryWithDictionary:@{@"clientApiList":supportApiList}];
            if (invalidJsApiArr.count > 0) {
                [paramDict setObject:invalidJsApiArr forKey:@"nonExistentLists"];
            }
            responseCallback([KKWebViewJavaScriptManager createSuccessResponseData:paramDict]);
            
            [strongSelf.registeredApiList addObjectsFromArray:supportApiList];
        }];
    }];
}

#pragma mark - Setter

- (void)setWebViewBridge:(KKWKWebViewJavascriptBridge *)webViewBridge {
    if ([_webViewBridge isEqual:webViewBridge]) {
        return;
    }
    _webViewBridge = webViewBridge;
    [_webViewBridge reset];
    [self registerInit];
    [self registerConfig];
}

- (void)setWebViewDelegate:(id<WKNavigationDelegate>)webViewDelegate {
    [self.webViewBridge setWebViewDelegate:webViewDelegate];
}

#pragma mark - Getter

- (NSMutableArray *)registeredApiList {
    if (!_registeredApiList) {
        _registeredApiList = [NSMutableArray array];
    }
    return _registeredApiList;
}

- (NSMutableArray *)notificationList {
    if (!_notificationList) {
        _notificationList = [NSMutableArray array];
    }
    return _notificationList;
}

@end
