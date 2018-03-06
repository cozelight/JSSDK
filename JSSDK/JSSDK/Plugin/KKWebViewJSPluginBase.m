//
//  KKWebViewJSPluginBase.m
//  JSSDK
//
//  Created by coze on 2017/12/6.
//  Copyright © 2017年 cozelight. All rights reserved.
//

#import "KKWebViewJSPluginBase.h"

@implementation KKWebViewJSPluginBase

- (BOOL)callBack:(NSDictionary *)dict {
    @try {
        NSString *js = [NSString stringWithFormat:@"fireTask(%ld), %@", self.taskId, dict];
        [self.webView evaluateJavaScript:js completionHandler:nil];
    }
    @catch (NSException *exception) {
        NSLog(@"%@",exception.debugDescription);
        return NO;
    }
    return NO;
}

- (void)errorCallback:(NSString *)errorMessage {
    NSString *js = [NSString stringWithFormat:@"onError(%ld), '%@'", self.taskId, errorMessage];
    [self.webView evaluateJavaScript:js completionHandler:nil];
}

@end
