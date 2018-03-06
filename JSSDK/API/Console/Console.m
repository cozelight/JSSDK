//
//  Console.m
//  JSSDK
//
//  Created by coze on 2017/12/6.
//  Copyright © 2017年 cozelight. All rights reserved.
//

#import "Console.h"

@implementation Console

- (void)log {
    if (self.data) {
        NSLog(@"JS->Console >>>> %@",self.data);
    }
}

@end
