//
//  biz_navigation.m
//  JSSDK
//
//  Created by coze on 2017/12/5.
//  Copyright © 2017年 cozelight. All rights reserved.
//

#import "biz_navigation.h"

@implementation biz_navigation

KKWEB_VIEW_JSAPI_SYNTHESIZE

- (void)setApiName:(NSString *)apiName {
    _apiName = apiName;
    if ([apiName isEqualToString:@"biz.navigation.setRight"]) {
        self.isNeedRegistId = 1;
    }
}

/**
 show: false,//控制按钮显示， true 显示， false 隐藏， 默认true
 control: true,//是否控制点击事件，true 控制，false 不控制， 默认false
 showIcon: true,//是否显示icon，true 显示， false 不显示，默认true； 注：具体UI以客户端为准
 text: '',//控制显示文本，空字符串表示显示默认文本
 onSuccess : function(result) {
 //如果control为true，则onSuccess将在发生按钮点击事件被回调
 },
 onFail : function(err) {}
 */
- (void)setRight {
    if ([self.jsManager.delegate respondsToSelector:@selector(handlerAPI:paramData:responseCallback:)]) {
        [self.jsManager.delegate handlerAPI:self.apiName paramData:self.paramData responseCallback:self.responseCallback];
    }
}

- (void)setLeft {
    if ([self.jsManager.delegate respondsToSelector:@selector(handlerAPI:paramData:responseCallback:)]) {
        [self.jsManager.delegate handlerAPI:self.apiName paramData:self.paramData responseCallback:self.responseCallback];
    }
}

@end
