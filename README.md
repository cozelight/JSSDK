## 前言

Hybrid 作为一种混合开发模式，依赖 Native 端的 Web 容器（UIWebView / WKWebView），上层使用 H5、JS 做业务开发。这种开发模式，非常有利于办公协同APP的开放平台搭建，由 Native 端提供API，供第三方使用开发、快速迭代。

## Hybrid APP 框架

一个完整的 Hybrid APP 框架主要包括 Manager、WebView 、Bridge、Cache 等模块。整个框架设计理念是组合，而不是继承，因此框架设计的不是一个 XXWebView / XXWebViewController 基类，使用者不需要在业务代码中继承 WebView 。框架设计的是一个 Manager 对象，使用者只需要跟自己业务中的任意一种 WebView 进行绑定，就可以拥有 Hybrid 的能力。

 - Manager 作为核心，负责处理 Hybrid 业务，校验和注册API

 - WebView 作为容器，负责展示前端页面，响应前端交互

 - Bridge 作为桥梁，负责 Native 和 JS 之间通信交互

 - Cache 作为缓存，负责缓存资源文件等

框架结构如下：

![Hybrid 框架](http://o8anxf7e1.bkt.clouddn.com/Hybrid%E6%A1%86%E6%9E%B6.png)

## WebView 容器

iOS8 以后苹果推出了一套新的 WKWebView，对于 UIWebView 和 WKWebView 的区别，可以参考 [教你使用 WKWebView 的正确姿势](https://mp.weixin.qq.com/s?__biz=MzI1MTE2NTE1Ng==&mid=2649516616&idx=1&sn=c16a7fc0ddaee2a6d5e1ad10373af9e3&chksm=f1efeac3c69863d5942da9ba250c39e29af97a7c1ac22fce49d65dc3967c49c811b0f566b2c6#rd)，本框架暂时选用 WKWebView 作为容器，针对 WKWebView 的问题，本框架做了以下解决方案：

#### Cookie 问题

前端抛弃对 Cookie 的依赖，改为使用 H5 的 Storage 能力。另 Native 提供存读接口，以备前端使用存储功能。

#### NSURLProtocol 支持

WKWebView 包含一个 `browsingContextController` 属性对象，该对象提供了 `registerSchemeForCustomProtocol` 和 `unregisterSchemeForCustomProtocol` 两个方法，能通过注册 scheme 来代理同类请求，符合注册 scheme 类型的请求会走 NSURLProtocol 协议。但是这种方案存在两个严重缺陷：post 请求 body 数据被清空；对 ATS 支持不足。

#### 跨域访问

iOS9 以后，可以通过 KVC 设置 `WKPreferences` 的 `allowFileAccessFromFileURLs` 和 `allowUniversalAccessFromFileURLs` 属性，来打开跨域访问。但是 iOS8 暂不支持。

#### Crash 白屏问题

在 WKWebView 白屏的时候，`webView.title` 会被置空，因此，可以在 `viewWillAppear` 的时候检测 `webView.title` 是否为空来 reload 页面。

#### 缓存问题

针对单个资源文件，可以对该资源地址加时间戳避开缓存。针对全局资源文件，需要手动清理缓存，iOS9 以后，系统提供了缓存管理接口 `WKWebsiteDataStore`。而 iOS8，只能通过手动删除文件来解决了，WKWebView 的缓存数据会存储在 ` ~/Library/Caches/BundleID/WebKit/` 目录下，可通过删除该目录来实现清理缓存。

## Bridge

由于容器选择是 WKWebView，所以 JS 调用 Native 端有两种方式 `URL拦截` 和 `messageHandler` 。下图为两种方式性能对比

![性能对比](http://o8anxf7e1.bkt.clouddn.com/%E4%BA%A4%E4%BA%92%E6%96%B9%E5%BC%8F%E6%80%A7%E8%83%BD%E5%AF%B9%E6%AF%94.png)

`messageHandler` 对比 `URL拦截` 性能大约提升了 20%，受益于 WKWebView，本框架采用 `messageHandler` + `evaluatingJavaScript` 的方式进行通信交互。

#### JS -> Native

##### Native 注入对象

```
//配置对象注入
[self.webView.configuration.userContentController addScriptMessageHandler:self name:@"nativeObject"];
//移除对象注入
[self.webView.configuration.userContentController removeScriptMessageHandlerForName:@"nativeObject"];
```

> 注意：如果当前 WebView 没用了，需要先移除这个对象注入，否则会造成内存泄漏，WebView 和所在 VC 循环引用，无法销毁。

##### JS 调用

```
//准备要传给native的数据，包括指令，数据，回调等
var data = {
    action:'xxxx',
    params:'xxxx',
    callback:'xxxx',
};
//传递给客户端
window.webkit.messageHandlers.nativeObject.postMessage(data);
```

##### Native 接收调用

当 JS 开始调用后，会调用到指定的 WKScriptMessageHandler 代理对象

```
-(void)userContentController:(WKUserContentController *)userContentController didReceiveScriptMessage:(WKScriptMessage *)message{
    //1 取出 name 是否与注入 name 匹配
    if (message.name isEqualToString:@"nativeObject") {
        //2 取出对象，做后续操作
        NSDictionary *msgBody = message.body;
    }
```

#### Native -> JS

对于 WKWebView ，除了`evaluatingJavaScript`，还有 WKUserScript 这个方式可以执行 JS 代码，他们之间是有区别的

- `evaluatingJavaScript` 是在客户端执行这条代码的时候立刻去执行当条JS代码

- WKUserScript 是预先准备好JS代码，当 WKWebView 加载 Dom 的时候，执行当条 JS 代码

很明显这个虽然是一种通信方式，但并不能随时随地进行通信，并不适合选则作为设计 Bridge 的核心方案。

#### 注入时机

并不是所有前端页面都需要用到 Native 能力，因此在需要用到 Native 能力的页面，才注入 JS 代码，为其提供 Native 能力。与前端约定，如果需要，就假跳转至一个指定的 `URL`, 然后客户端在代理方法 `webView:(WKWebView *)webViewdecidePolicyForNavigationAction:decisionHandler:` 里判断 `URL` 是否为指定的 `URL`，如果是，则执行注入。

```
- (void)webView:(WKWebView *)webView decidePolicyForNavigationAction:(WKNavigationAction *)navigationAction decisionHandler:(void (^)(WKNavigationActionPolicy))decisionHandler {
    NSURL *url = navigationAction.request.URL;
    if ([url.absoluteString isEqualToString:@"指定URL"]) {
        // 执行注入 JS 代码
        
        decisionHandler(WKNavigationActionPolicyCancel);
        return;
    }
    decisionHandler(WKNavigationActionPolicyAllow);
}
```

#### Bridge 框架

整个 Native 和 JS 的 Bridge 交互流程如下图所示：

![brdige流程](http://o8anxf7e1.bkt.clouddn.com/bridge%E6%B5%81%E7%A8%8B.png)


在 Native / JS 端，创建 Bridge 对象，该对象需包含：

##### property

- messageHandlers 字典，以 handlerName 作为 key，保存对应 function
- responseCallbacks 字典，以 callbackId 作为 key，保存响应 function

##### function

- doSend: 调用另一端方法，传递 message 字典参数
- responseAnotherMethod: 响应另一端的调用，接收 message 字典参数


## Manager

Manager 为整个 Hybrid 核心，负责 JS 方法到 Native 端的映射，可灵活扩展。利用 runtime 特性，使用得到的 className 和 functionName 反射出指定的对象，并执行指定函数。

#### 权限验证

针对打开的 WebView, 是否拥有合法使用 Hybrid 的权限需要进行验证，只有验证通过的页面，才能使用原生提供的能力。Manager 提供入口，具体验证由上层实现。

```
- (void)authenticationSignatureParameter:(NSDictionary *)parameter comlete:(void (^)(NSError *error))complete;
```

#### 组件协议

JS 页面加载完，在使用 Native 能力之前，需要进行注册，即告知 Native 当前页面所需要使用的 API 列表。Manager 处理该流程，验证 Native 是否实现该 API，同时把 API 转换成对象，对象遵循以下协议：

```
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
```

#### 反射函数

Manager 把 API 转换成对象时，利用 Objective-C 的 runtime 反射机制：

```
Class cls = NSClassFromString(className);
    if ([cls conformsToProtocol:@protocol(KKWebViewJSApiBaseProtocol)]) {
        id<KKWebViewJSApiBaseProtocol> obj = [[cls alloc] init];
        if ([obj respondsToSelector:NSSelectorFromString(functionName)]) {
#pragma clang diagnostic push
#pragma clang diagnostic ignored "-Warc-performSelector-leaks"
            [obj performSelector:NSSelectorFromString(functionName)];
#pragma clang diagnostic pop
            return obj;
        } else {
            NSLog(@"function is not found");
            return nil;
        }
    } else {
        NSLog(@"clss is not found");
        return nil;
    }
```


## 参考文章

[教你使用 WKWebView 的正确姿势](https://mp.weixin.qq.com/s?__biz=MzI1MTE2NTE1Ng==&mid=2649516616&idx=1&sn=c16a7fc0ddaee2a6d5e1ad10373af9e3&chksm=f1efeac3c69863d5942da9ba250c39e29af97a7c1ac22fce49d65dc3967c49c811b0f566b2c6#rd)

[WKWebView 那些坑](https://mp.weixin.qq.com/s/rhYKLIbXOsUJC_n6dt9UfA)

[浅谈Hybrid技术的设计与实现](http://www.cnblogs.com/yexiaochai/p/4921635.html)

[自己动手打造基于 WKWebView 的混合开发框架](https://lvwenhan.com/ios/460.html)

[58 同城 iOS 客户端 Hybrid 框架探索](http://blog.csdn.net/byeweiyang/article/details/75102051)

[从零收拾一个hybrid框架](http://awhisper.github.io/2018/01/02/hybrid-jscomunication/)

