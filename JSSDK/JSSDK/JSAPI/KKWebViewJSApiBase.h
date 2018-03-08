//
//  KKWebViewJSApiBase.h
//  JSSDK
//
//  Created by coze on 2017/12/4.
//  Copyright © 2017年 cozelight. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "JSSDKErrCode.h"
#import "KKWebViewJavaScriptManager.h"

#define KKWEB_VIEW_JSAPI_SYNTHESIZE @synthesize apiName = _apiName, isNeedRegistId = _isNeedRegistId, isEvent = _isEvent, paramData = _paramData, responseCallback = _responseCallback, jsManager = _jsManager;

@protocol KKWebViewJSApiBaseProtocol <NSObject>

@required
/// api名字
@property (nonatomic, copy) NSString *apiName;
/// 是否支持js多次回调
@property (nonatomic, assign) NSInteger isNeedRegistId;
/// 是否为事件类型，客户端调用，类似发通知给JS
@property (nonatomic, assign) NSInteger isEvent;
/// api接口参数数据
@property (nonatomic, strong) NSDictionary *paramData;
/// api接口响应回调
@property (nonatomic, copy) WVJBResponseCallback responseCallback;

@property (nonatomic, weak) KKWebViewJavaScriptManager *jsManager;

@end;

