# MagicWebViewWebP
非常方便的引入UIWebView、WKWebView对WebP图片的支持。🎉🎉🎉

![](http://upload-images.jianshu.io/upload_images/1519620-4d5671fb3295889d.png?imageMogr2/auto-orient/strip%7CimageView2/2/w/1240)


> 移动端应用往往有大量的图片展示场景，图片的大小对企业至关重要。WebP 作为一种更高效的图片编码格式，平均大小比 PNG/JPG/ GIF/动态 GIF格式减少 70%（[对比测试页面](https://www.upyun.com/webp)），且质量没有明显的差别，是其他图片格式极佳的替代者。



## 一、MagicWebViewWebP.framework架构

![](http://upload-images.jianshu.io/upload_images/1519620-142737af1892e4cd.jpg?imageMogr2/auto-orient/strip%7CimageView2/2/w/1240)


| 主要文件                       | 说明                                       |
| -------------------------- | ---------------------------------------- |
| MagicWebViewWebPManager    | **（引用文件）**管理MagicURLProtocol的注册、销毁MagicURLProtocol |
| MagicURLProtocol           | 继承NSURLProtocol用于截获url                   |
| NSURLProtocol+MagicWebView | 扩展NSURLProtocol用于注册、销毁Scheme             |



| 依赖         | 说明            |
| ---------- | ------------- |
| SDWebImage | 使用了webP相关部分模块 |
| libwebp    | webP依赖文件      |


![](http://upload-images.jianshu.io/upload_images/1519620-a1dd7bb4e828c239.gif?imageMogr2/auto-orient/strip)


## 二、说明

### MagicURLProtocol

> MagicURLProtocol继承于`NSURLProtocol`，实现了对webP图片网络请求进行拦截，将拦截的请求使用`NSURLConnection`(也可以使用`NSURLSession`)加载数据，然后利用SDWebImage中`UIImage+WebP`提供加载webP图片的能力，并将加载好的`UIImage`转化为`NSData`返回，实现webP图片的加载。



1、NSURLProtocol主要步骤？

```
注册—>拦截—>转发—>回调—>结束
```



2、继承NSURLProtocol必须实现的方法？

```objective-c
+ (BOOL)canInitWithRequest:(NSURLRequest *)request;
+ (NSURLRequest *)canonicalRequestForRequest:(NSURLRequest *)request;
- (void)startLoading;
- (void)stopLoading;
```



3、什么是NSURLProtocol？

> NSURLProtocol作为URL Loading System中的一个独立部分存在，能够拦截所有的URL Loading System发出的网络请求，拦截之后便可根据需要做各种自定义处理，是iOS网络层实现AOP(面向切面编程)的终极利器，所以功能和影响力都是非常强大的。

![URL Loading System的图](http://upload-images.jianshu.io/upload_images/1519620-595e0d8980918b86.png?imageMogr2/auto-orient/strip%7CimageView2/2/w/1240)

> 1.NSURLProtocol可以拦截的网络请求包括NSURLSession，NSURLConnection以及UIWebVIew。
> 2.基于CFNetwork的网络请求，以及WKWebView的请求是无法拦截的。
> 3.现在主流的iOS网络库，例如AFNetworking，Alamofire等网络库都是基于NSURLSession或NSURLConnection的，所以这些网络库的网络请求都可以被NSURLProtocol所拦截。



```objective-c
//MagicURLProtocol.h
#import <Foundation/Foundation.h>
@interface MagicURLProtocol : NSURLProtocol
  
@end
```



```objective-c
//MagicURLProtocol.m
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
    //NSString *urlString = newRequest.URL.absoluteString;
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
```


### MagicWebViewWebPManager

> MagicWebViewWebPManager封装了支持UIWebView、WKWebView注册和销毁MagicURLProtocol。
>
> 特别注意：NSURLProtocol 一旦被注册将会使整个app的request请求都会被拦截，进入Web时注册，退出Web取消注册。在使用的时候需要特别注意。

```objective-c
//MagicWebViewWebPManager.h
#import <Foundation/Foundation.h>

@interface MagicWebViewWebPManager : NSObject
+ (MagicWebViewWebPManager *)shareManager;
- (void)registerMagicURLProtocolWebView:(id)webView;       //注册 MagicURLProtocol
- (void)unregisterMagicURLProtocolWebView:(id)webView;     //销毁 MagicURLProtocol
@end
```



```objective-c
//MagicWebViewWebPManager.m
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
```



### NSURLProtocol+MagicWebView

> NSURLProtocol+MagicWebView用于提供WKWebView对NSURLProtocol的支持能力。
>
> UIWebView默认支持NSURLProtocol，如果需要WKWebView也支持NSURLProtocol，则需要扩展，具体代码如下。

```objective-c
//NSURLProtocol+MagicWebView.h
#import <Foundation/Foundation.h>

@interface NSURLProtocol (MagicWebView)
+ (void)wk_registerScheme:(NSString *)scheme;       //注册协议
+ (void)wk_unregisterScheme:(NSString *)scheme;     //注销协议
@end
```



```objective-c
//NSURLProtocol+MagicWebView.m
#import "NSURLProtocol+MagicWebView.h"
#import <WebKit/WebKit.h>

FOUNDATION_STATIC_INLINE Class ContextControllerClass() {
    static Class cls;
    if (!cls) {
        cls = [[[WKWebView new] valueForKey:@"browsingContextController"] class];
    }
    return cls;
}
FOUNDATION_STATIC_INLINE SEL RegisterSchemeSelector() {
    return NSSelectorFromString(@"registerSchemeForCustomProtocol:");
}
FOUNDATION_STATIC_INLINE SEL UnregisterSchemeSelector() {
    return NSSelectorFromString(@"unregisterSchemeForCustomProtocol:");
}

@implementation NSURLProtocol (MagicWebView)

+ (void)wk_registerScheme:(NSString *)scheme {
    Class cls = ContextControllerClass();
    SEL sel = RegisterSchemeSelector();
    if ([(id)cls respondsToSelector:sel]) {
#pragma clang diagnostic push
#pragma clang diagnostic ignored "-Warc-performSelector-leaks"
        [(id)cls performSelector:sel withObject:scheme];
#pragma clang diagnostic pop
    }
}

+ (void)wk_unregisterScheme:(NSString *)scheme {
    Class cls = ContextControllerClass();
    SEL sel = UnregisterSchemeSelector();
    if ([(id)cls respondsToSelector:sel]) {
#pragma clang diagnostic push
#pragma clang diagnostic ignored "-Warc-performSelector-leaks"
        [(id)cls performSelector:sel withObject:scheme];
#pragma clang diagnostic pop
    }
}

@end
```



![](http://upload-images.jianshu.io/upload_images/1519620-483db08a42d94e02.gif?imageMogr2/auto-orient/strip)

## 三、使用

1、将MagicWebViewWebP.framework导入工程。

![](http://upload-images.jianshu.io/upload_images/1519620-c7cb51b0db485e4a.jpg?imageMogr2/auto-orient/strip%7CimageView2/2/w/1240)




2、引入头文件。

```objective-c
#import <MagicWebViewWebP/MagicWebViewWebPManager.h>
```



3、webView加载请求之前，注册MagicURLProtocol。

```objective-c
- (void)viewDidLoad {
    [super viewDidLoad];
    // Do any additional setup after loading the view. 
    // 注册协议支持webP
    [[MagicWebViewWebPManager shareManager] registerMagicURLProtocolWebView:self.wkWebView];
    // 加载请求
    NSURLRequest *request = [NSURLRequest requestWithURL:[NSURL URLWithString:_requestURLString]];
    [self.wkWebView loadRequest:request];
}
```



4、dealloc中销毁MagicURLProtocol。

> 若有特殊需求，需要在web页面退出时销毁MagicURLProtocol，否则会拦截整个app的网络请求。

```objective-c
// 销毁
-(void)dealloc{
    [[MagicWebViewWebPManager shareManager] unregisterMagicURLProtocolWebView:self.wkWebView];
}
```



5、可以加载http://isparta.github.io/compare-webp/index.html#12345来检测webP显示效果。

![](http://upload-images.jianshu.io/upload_images/1519620-4c92df2dec6b3c2d.gif?imageMogr2/auto-orient/strip)



## 三、开源地址

> MagicWebViewWebP.framework已经开源，喜欢的小伙伴儿可以Star。⭐️⭐️⭐️⭐️⭐️

[MagicWebViewWebP开源](https://github.com/Luis-X/MagicWebViewWebP)

![](http://upload-images.jianshu.io/upload_images/1519620-06f87594bfb4045f.gif?imageMogr2/auto-orient/strip)

## 参考文章

[探究WebP一些事儿](https://aotu.io/notes/2016/06/23/explore-something-of-webp/index.html)
[移动端WebP兼容解决方案](https://sdk.cn/news/6882)
[NSURLProtocol 全攻略](http://tech.lede.com/2017/02/15/rd/iOS/iOS_NSURLProtocol/)
[WKWebView 那些坑](https://mp.weixin.qq.com/s?__biz=MzA3NTYzODYzMg==&mid=2653578513&idx=1&sn=961bf5394eecde40a43060550b81b0bb&chksm=84b3b716b3c43e00ee39de8cf12ff3f8d475096ffaa05de9c00ff65df62cd73aa1cff606057d&mpshare=1&scene=1&srcid=0214nkrYxApaVTQcGw3U9Ryp)