//
//  NSURLProtocol+MagicWebView.h
//  MagicCubeKit
//
//  Created by LuisX on 2017/8/30.
//  Copyright © 2017年 LuisX. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface NSURLProtocol (MagicWebView)
+ (void)wk_registerScheme:(NSString *)scheme;       //注册协议
+ (void)wk_unregisterScheme:(NSString *)scheme;     //注销协议
@end
