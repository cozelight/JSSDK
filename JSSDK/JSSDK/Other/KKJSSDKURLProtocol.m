//
//  IMOJSSDKURLProtocol.h
//  imoffice
//
//  Created by ganzhen on 16/6/13.
//  Copyright © 2016年 IMO. All rights reserved.
//

#import "KKJSSDKURLProtocol.h"
#import <UIKit/UIKit.h>

NSString *const JSSDK_AVATAR_SCHEME = @"kkjssdkavatar";

@implementation KKJSSDKURLProtocol

+ (BOOL)canInitWithRequest:(NSURLRequest*)theRequest {
    
    if ([theRequest.URL.scheme caseInsensitiveCompare:JSSDK_AVATAR_SCHEME] == NSOrderedSame) {
        return YES;
    }
    return NO;
}

+ (NSURLRequest*)canonicalRequestForRequest:(NSURLRequest*)theRequest {
    
    return theRequest;
}

- (void)startLoading {
    
    NSLog(@"%s, request.URL = %@", __func__, self.request.URL);
    NSURLResponse *response = [[NSURLResponse alloc] initWithURL:[self.request URL]
                                                        MIMEType:@"image/png"
                                           expectedContentLength:-1
                                                textEncodingName:nil];
    
    NSString *imagePath = [self.request.URL.relativeString stringByReplacingOccurrencesOfString:[NSString stringWithFormat:@"%@://",JSSDK_AVATAR_SCHEME] withString:@""];
    
    UIImage *image = [UIImage imageNamed:imagePath];
    
    NSData *data = UIImagePNGRepresentation(image);
    
    [[self client] URLProtocol:self didReceiveResponse:response cacheStoragePolicy:NSURLCacheStorageNotAllowed];
    [[self client] URLProtocol:self didLoadData:data];
    [[self client] URLProtocolDidFinishLoading:self];
}

- (void)stopLoading {
    NSLog(@"%s something went wrong!", __func__);
}

@end
