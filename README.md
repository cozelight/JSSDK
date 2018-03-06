## JS-SDK

### 一、前言

JS-SDK方便开发者建立Native与JS之间的桥梁，目前只支持**WKWebView**作为容器

支持`JS-API`拓展和`JS-Plugin`拓展两种方式

### 二、使用

1. 导入头文件，声明属性

   ```objective-c
   #import "KKWebViewJavaScriptManager.h"
   ...
   @property KKWebViewJavaScriptManager *jsManager
   ```


2. 创建 KKWebViewJavaScriptManager

   ```objective-c
   self.jsManager = [KKWebViewJavaScriptManager managerForWebView:self.webView containerVC:self];
   ```


3. KKWebViewJavaScriptManagerDelegate

   ```objective-c
   @required

   /// 验证签名，用于客户端验证JS是否合法
   - (void)authenticationSignatureParameter:(NSDictionary *)parameter comlete:(void (^)(NSError *error))complete;

   @optional

   /// 检查API是否合法, 不验证，默认合法。
   - (BOOL)checkAPILegal:(NSString *)apiName;

   /// JS调用Native
   - (void)handlerAPI:(NSString *)apiName
            paramData:(NSDictionary *)paramData
     responseCallback:(WVJBResponseCallback)responseCallback;
   ```

### 三、拓展JS-API 

例如实现 `device.notification.alert` ：

1. 新建类文件`device_notification` 必须名称与api名称一致，**点符合**必须改成**下划线**。遵循`KKWebViewJSApiBaseProtocol`协议

   ```objective-c
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
   ```

2. `device_notification` 实现`alert`方法

   ```objective-c
   - (void)alert {
     //js传的参数
     NSDictionary *paramDict = self.paramData;
     //业务实现
     ...
     //失败
     id result = [KKWebViewJavaScriptManager createFailureResponseDataWithErrorcode:1 errormsg:@"failure"];
     // or 成功
     result = [KKWebViewJavaScriptManager createSuccessResponseData:resultData];
     //响应回调
     self.responseCallback(result);
   }
   ```


3. API是事件类型，即由Native调用该API，抛事件给JS。

   比如透传通知`ccwork.transport.transportRespond`，当客户端接到透传后，调用该API，抛出通知事件给JS端。Native端只需要在合适时机调用API，对于该API空实现。

   ```objective-c
   // 在ccwork_transport的.m文件
   // 重写setApiName方法
   - (void)setApiName:(NSString *)apiName {
       _apiName = apiName;
       if ([apiName isEqualToString:@"ccwork.transport.transportRespond"]) {
   		// 标识该API为事件类型
           self.isEvent = 1;
       }
   }

   // 空实现transportRespond方法
   - (void)transportRespond {}

   // 在其它地方，合适的时机调用 ccwork.transport.transportRespond 
   - (void)receiveTransportNotification {
    	[self.jsManager.webViewBridge callHandler:@"ccwork.transport.transportRespond" data:paramDict];
   }
   ```

4. API是需要多次回调

   比如离线下载`ccwork.offlineApp.download`

   ```objective-c
   // 在ccwork_offlineApp的.m文件
   // 重写setApiName方法
   - (void)setApiName:(NSString *)apiName {
       _apiName = apiName;
       if ([apiName isEqualToString:@"ccwork.offlineApp.download"]) {
   		// 标识该API需要多次回调
           self.isNeedRegistId = 1;
       }
   }

   // 空实现download方法
   - (void)download {
     	// 获取JS回调方法名
     	NSString *registerId = self.paramData[@"appBridgeRegisterId"];
     	// 业务处理
     	...
     	// 下载回调
    	[self.jsManager.webViewBridge callHandler:registerId data:[KKWebViewJavaScriptManager createProgressResponseData:progressData]]; 
     	// 下载完成，成功 or 失败
     	if (error) {
              self.responseCallback([KKWebViewJavaScriptManager createFailureResponseDataWithErrorcode:error.code errormsg:nil]);
           } else {
              self.responseCallback([KKWebViewJavaScriptManager createSuccessResponseData:nil]);
           }
   }
   ```



