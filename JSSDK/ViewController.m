//
//  ViewController.m
//  JSSDK
//
//  Created by coze on 2017/11/30.
//  Copyright © 2017年 cozelight. All rights reserved.
//

#import "ViewController.h"
#import <WebKit/WebKit.h>
#import "KKWebViewJavaScriptManager.h"

typedef void(^barButtonDidClick)(UIButton *barButton);

@interface ViewController () <WKNavigationDelegate, KKWebViewJavaScriptManagerDelegate>

@property (nonatomic, strong) WKWebView *webView;
@property (nonatomic, strong) KKWebViewJavaScriptManager *jsManager;

@property (nonatomic, strong) UIButton *rightButton;
@property (nonatomic, copy) barButtonDidClick rightButtonAction;

@end

@implementation ViewController

- (void)dealloc {
    
}

- (void)viewDidLoad {
    [super viewDidLoad];
    
    WKWebViewConfiguration *conf = [[WKWebViewConfiguration alloc] init];
    self.webView = [[WKWebView alloc] initWithFrame:self.view.bounds configuration:conf];
    
    self.jsManager = [KKWebViewJavaScriptManager managerForWebView:self.webView containerVC:self];
    self.jsManager.delegate = self;
    [self.jsManager installPluginJS:@[@"Base",@"Console"]];
    
    [self.view addSubview:self.webView];
    
    [self.webView loadRequest:[NSURLRequest requestWithURL:[NSURL URLWithString:@"http://192.168.1.251:8282/fed/cc-sdk"]]];
    
    UIBarButtonItem *rightButtonItem = [[UIBarButtonItem alloc] initWithCustomView:self.rightButton];
    self.navigationItem.rightBarButtonItems = @[rightButtonItem];
}

- (BOOL)checkAPILegal:(NSString *)apiName {
    if ([apiName isEqualToString:@"biz.navigation.setLeft"]) {
        return NO;
    }
    return YES;
}

- (void)authenticationSignatureParameter:(NSDictionary *)parameter comlete:(void (^)(NSError *))complete {
    complete(nil);
}

- (void)handlerAPI:(NSString *)apiName
         paramData:(NSDictionary *)paramData
  responseCallback:(WVJBResponseCallback)responseCallback {
    
    if ([apiName isEqualToString:@"biz.navigation.setRight"]) {
        
        BOOL show = NO;
        if (paramData[@"show"] && [paramData[@"show"] boolValue]) {
            show = YES;
        }
        
        if (!show) {
            self.navigationItem.rightBarButtonItems = nil;
            return;
        }
        
        UIButton *rightBtn = self.rightButton;
        
        NSString *text = rightBtn.currentTitle;
        if (paramData[@"text"]) {
            text = paramData[@"text"];
        }
        [rightBtn setTitle:text forState:UIControlStateNormal];
        rightBtn.titleLabel.font = [UIFont systemFontOfSize:16.0];
        
        BOOL control = NO;
        if (paramData[@"control"] && [paramData[@"control"] boolValue]) {
            control = YES;
        }
        
        if (control) {
            NSString *registerId = paramData[@"appBridgeRegisterId"];
            __weak typeof(self) weakSelf = self;
            self.rightButtonAction = ^(UIButton *barButton){
                [weakSelf.jsManager.webViewBridge callHandler:registerId data:[KKWebViewJavaScriptManager createSuccessResponseData:nil]];
            };
        } else {
            self.rightButtonAction = nil;
        }
        if (rightBtn.hidden) {
            rightBtn.hidden = NO;
        }
        self.navigationItem.rightBarButtonItems = @[[[UIBarButtonItem alloc] initWithCustomView:rightBtn]];
    }
}

- (void)rightButtonClick {
    if (self.rightButtonAction) {
        self.rightButtonAction(self.rightButton);
    } else {
        if (self.jsManager.notificationList.count > 0) {
            [self.jsManager.webViewBridge callHandler:@"device.notification.listeningEvent"
                                                 data:[KKWebViewJavaScriptManager createSuccessResponseData:@"success"]];
        }
    }
}

-(UIButton *)rightButton {
    if (!_rightButton) {
        _rightButton = [UIButton buttonWithType:UIButtonTypeCustom];
        _rightButton.frame = CGRectMake(0, 0, 40, 40);
        [_rightButton setTitle:@"更多" forState:UIControlStateNormal];
        [_rightButton setTitleColor:[UIColor blackColor] forState:UIControlStateNormal];
        [_rightButton addTarget:self action:@selector(rightButtonClick) forControlEvents:UIControlEventTouchUpInside];
    }
    return _rightButton;
}

@end
