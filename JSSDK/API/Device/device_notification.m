//
//  device_notification.m
//  JSSDK
//
//  Created by coze on 2017/12/4.
//  Copyright © 2017年 cozelight. All rights reserved.
//

#import "device_notification.h"

@implementation device_notification

KKWEB_VIEW_JSAPI_SYNTHESIZE

- (void)setApiName:(NSString *)apiName {
    _apiName = apiName;
    if ([apiName isEqualToString:@"device.notification.listeningEvent"]) {
        self.isEvent = 1;
    }
}

- (void)alert {
    
    NSLog(@"%@, text = %@",self.apiName, self.paramData[@"message"]);
    self.responseCallback([KKWebViewJavaScriptManager createSuccessResponseData:self.paramData[@"title"]]);
}

- (void)registerEvent {
    [self.jsManager.notificationList addObject:self.paramData[@"event"]];
    self.responseCallback([KKWebViewJavaScriptManager createSuccessResponseData:@"success"]);
}

- (void)listeningEvent{}

@end
