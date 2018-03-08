//
//  JSSDKErrCode.h
//  Kook
//
//  Created by shizhanying on 2017/5/2.
//  Copyright © 2017年 Kook. All rights reserved.
//

#ifndef JSSDKErrCode_h
#define JSSDKErrCode_h


typedef NS_ENUM(NSInteger, JSSDKErrCode) {
    JSSDKErrCodeProgress = -100,             //进度回调，下载or上传
    JSSDKErrCodeSuc = 0,                     //成功
    JSSDKErrCodeParamError = 1,          // 参数错误
    JSSDKErrCodeIllegalCorpId = 2,           //非法corpId
    JSSDKErrCodeNotSupportAppAwake = 3,      //不支持唤醒的app
    JSSDKErrCodeInvalidApi    = 4,           //尚未支持的api
};



#endif /* JSSDKErrCode_h */
