//
//  MagicWebViewWebPManager.h
//  MagicCubeKit
//
//  Created by LuisX on 2017/8/30.
//  Copyright © 2017年 LuisX. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface MagicWebViewWebPManager : NSObject
+ (MagicWebViewWebPManager *)shareManager;
- (void)registerMagicURLProtocolWebView:(id)webView;       //注册 MagicURLProtocol
- (void)unregisterMagicURLProtocolWebView:(id)webView;     //销毁 MagicURLProtocol
@end
