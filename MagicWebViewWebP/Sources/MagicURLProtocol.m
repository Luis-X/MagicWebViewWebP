//
//  MagicURLProtocol.m
//  MagicCubeKit
//
//  Created by LuisX on 2017/8/30.
//  Copyright © 2017年 LuisX. All rights reserved.
//

#import "MagicURLProtocol.h"

#ifdef SD_WEBP
#import "UIImage+WebP.h"
#endif

static NSString *const MagicURLProtocolKey = @"MagicURLProtocol-already-handled";

@interface MagicURLProtocol()<NSURLConnectionDataDelegate>
@property (strong, nonatomic) NSURLConnection *connection;
@property (strong, nonatomic) NSMutableData *recData;
@end

@implementation MagicURLProtocol

- (void)dealloc{
    self.recData = nil;
    self.connection = nil;
}

/**
 判断是否启用SD_WEBP 并且图片格式为webp 如果为YES 则标记请求需要自行处理并且防止无限循环 为NO则不处理
 Build Settings -- Preprocessor Macros, 添加 SD_WEBP=1
 */
+ (BOOL)canInitWithRequest:(NSURLRequest *)request {
    BOOL useCustomUrlProtocol = NO;
    NSString *urlString = request.URL.absoluteString;
    if (!SD_WEBP || ([urlString.pathExtension compare:@"webp"] != NSOrderedSame)) {
        useCustomUrlProtocol = NO;
    }else {
        if ([NSURLProtocol propertyForKey:MagicURLProtocolKey inRequest:request] == nil) {
            useCustomUrlProtocol = YES;
        }else {
            useCustomUrlProtocol = NO;
        }
    }
    return useCustomUrlProtocol;
}

+ (NSURLRequest *)canonicalRequestForRequest:(NSURLRequest *)request {
    return request;
}

// 将截获的请求使用NSURLConnection | NSURLSession 获取数据
// (此处使用NSURLConnection)
- (void)startLoading{
    NSMutableURLRequest *newRequest = [self cloneRequest:self.request];
    NSString *urlString = newRequest.URL.absoluteString;
    //NSLog(@"######截获WebP url:%@",urlString);
    [NSURLProtocol setProperty:@YES forKey:MagicURLProtocolKey inRequest:newRequest];
    [self sendRequest:newRequest];
}

- (void)stopLoading{
    if (self.connection) {
        [self.connection cancel];
    }
    self.connection = nil;
}

#pragma mark - dataDelegate
//复制Request对象
- (NSMutableURLRequest *)cloneRequest:(NSURLRequest *)request{
    NSMutableURLRequest *newRequest = [NSMutableURLRequest requestWithURL:request.URL cachePolicy:request.cachePolicy timeoutInterval:request.timeoutInterval];
    
    newRequest.allHTTPHeaderFields = request.allHTTPHeaderFields;
    [newRequest setValue:@"image/webp,image/*;q=0.8" forHTTPHeaderField:@"Accept"];
    if (request.HTTPMethod) {
        newRequest.HTTPMethod = request.HTTPMethod;
    }
    if (request.HTTPBodyStream) {
        newRequest.HTTPBodyStream = request.HTTPBodyStream;
    }
    if (request.HTTPBody) {
        newRequest.HTTPBody = request.HTTPBody;
    }
    newRequest.HTTPShouldUsePipelining = request.HTTPShouldUsePipelining;
    newRequest.mainDocumentURL = request.mainDocumentURL;
    newRequest.networkServiceType = request.networkServiceType;
    return newRequest;
    
}

#pragma mark - 网络请求
- (void)sendRequest:(NSURLRequest *)request{
    self.connection = [[NSURLConnection alloc] initWithRequest:request delegate:self];
}

#pragma mark - NSURLConnectionDataDelegate
/**
 * 收到服务器响应
 */
- (void)connection:(NSURLConnection *)connection didReceiveResponse:(NSURLResponse *)response{
    NSURLResponse *returnResponse = response;
    [self.client URLProtocol:self didReceiveResponse:returnResponse cacheStoragePolicy:NSURLCacheStorageAllowed];
}
/**
 * 接收数据
 */
- (void)connection:(NSURLConnection *)connection didReceiveData:(NSData *)data{
    if (!self.recData) {
        self.recData = [NSMutableData new];
    }
    if (data) {
        [self.recData appendData:data];
    }
}
/**
 * 重定向
 */
- (nullable NSURLRequest *)connection:(NSURLConnection *)connection willSendRequest:(NSURLRequest *)request redirectResponse:(nullable NSURLResponse *)response{
    if (response) {
        [self.client URLProtocol:self wasRedirectedToRequest:request redirectResponse:response];
    }
    return request;
}
/**
 * 加载完毕
 */
- (void)connectionDidFinishLoading:(NSURLConnection *)connection{
    NSData *imageData = self.recData;
#ifdef SD_WEBP
    UIImage *image = [UIImage sd_imageWithWebPData:self.recData];
    imageData = UIImagePNGRepresentation(image);
    if (!imageData) {
        imageData = UIImageJPEGRepresentation(image, 1);
    }
#endif
    [self.client URLProtocol:self didLoadData:imageData];
    [self.client URLProtocolDidFinishLoading:self];
}
/**
 * 加载失败
 */
- (void)connection:(NSURLConnection *)connection didFailWithError:(NSError *)error{
    [self.client URLProtocol:self didFailWithError:error];
}

@end
