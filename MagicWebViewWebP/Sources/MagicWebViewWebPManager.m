//
//  MagicWebViewWebPManager.m
//  MagicCubeKit
//
//  Created by LuisX on 2017/8/30.
//  Copyright © 2017年 LuisX. All rights reserved.
//
// 参考：https://liuwentao1314.github.io/2017/04/13/webp-image-format-ios/

#import "MagicWebViewWebPManager.h"
#import "NSURLProtocol+MagicWebView.h"
#import <WebKit/WebKit.h>

static NSString *const MagicURLProtocol_String = @"MagicURLProtocol";

@implementation MagicWebViewWebPManager

+ (MagicWebViewWebPManager *)shareManager{
    static MagicWebViewWebPManager *manger;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        manger = [[MagicWebViewWebPManager alloc] init];
    });
    return manger;
}

#pragma mark - WebView支持webP
// NSURLProtocol 一旦被注册将会使整个App的request请求都会被拦截,进入Web时注册,退出Web取消注册
/**
 注册 MagicURLProtocol
 */
- (void)registerMagicURLProtocolWebView:(id)webView{
    if ([webView isKindOfClass:[WKWebView class]]) {
        [NSURLProtocol registerClass:NSClassFromString(MagicURLProtocol_String)];
        [NSURLProtocol wk_registerScheme:@"http"];
        [NSURLProtocol wk_registerScheme:@"https"];
    }
    if ([webView isKindOfClass:[UIWebView class]]){
        [NSURLProtocol registerClass:NSClassFromString(MagicURLProtocol_String)];
    }
}

/**
 销毁 MagicURLProtocol
 */
- (void)unregisterMagicURLProtocolWebView:(id)webView{
    if ([webView isKindOfClass:[WKWebView class]]) {
        [NSURLProtocol unregisterClass:NSClassFromString(MagicURLProtocol_String)];
        [NSURLProtocol wk_unregisterScheme:@"http"];
        [NSURLProtocol wk_unregisterScheme:@"https"];
    }
    if ([webView isKindOfClass:[UIWebView class]]){
        [NSURLProtocol unregisterClass:NSClassFromString(MagicURLProtocol_String)];
    }
}

@end
