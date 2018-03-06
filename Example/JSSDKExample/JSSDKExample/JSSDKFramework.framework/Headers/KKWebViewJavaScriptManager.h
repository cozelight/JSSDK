//
//  KKWebViewJavaScriptManager.h
//  JSSDK
//
//  Created by coze on 2017/12/4.
//  Copyright © 2017年 cozelight. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "KKWKWebViewJavascriptBridge.h"

@protocol KKWebViewJavaScriptManagerDelegate<NSObject>

- (void)handlerAPI:(NSString *)apiName
         paramData:(NSDictionary *)paramData
  responseCallback:(WVJBResponseCallback)responseCallback;

@end

@interface KKWebViewJavaScriptManager : NSObject

@property (nonatomic, weak) UIViewController *containerVC;
@property (nonatomic, strong) KKWKWebViewJavascriptBridge *webViewBridge;
@property (nonatomic, weak) id<KKWebViewJavaScriptManagerDelegate> delegate;

/// 通知事件列表，存储web已注册事件，需手动管理
@property (nonatomic, strong) NSMutableArray *notificationList;
/// 检查API是否合法block
@property (nonatomic, copy) BOOL (^checkAPILegal)(NSString *apiName);

/// 注册时检查API是否合法，如不提供检查block，默认合法。
- (BOOL)checkAPILegal:(NSString *)apiName;

/// 获取当前已注册API列表
- (NSArray *)getRegisteredAPIList;

/// 安装插件列表，需在页面加载前设置
- (void)installPluginJS:(NSArray <__kindof NSString *> *)pluginJS;

/// Class Methods
+ (instancetype)managerForWebView:(WKWebView *)webView containerVC:(UIViewController *)containerVC;

+ (NSDictionary *)createSuccessResponseData:(id)data;
+ (NSDictionary *)createFailureResponseDataWithErrorcode:(NSInteger)errorcode errormsg:(id)errormsg;
+ (NSDictionary *)createProgressResponseData:(id)data;

@end
