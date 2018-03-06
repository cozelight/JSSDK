//
//  KKWebViewJSPluginBase.h
//  JSSDK
//
//  Created by coze on 2017/12/6.
//  Copyright © 2017年 cozelight. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <WebKit/WebKit.h>

@interface KKWebViewJSPluginBase : NSObject

@property (nonatomic, strong) WKWebView *webView;
@property (nonatomic, assign) NSUInteger taskId;

/// JS参数
@property (nonatomic, copy) NSString *data;

/// JS响应成功回调
- (BOOL)callBack:(NSDictionary *)dict;
/// JS响应错误回调
- (void)errorCallback:(NSString *)errorMessage;

@end
