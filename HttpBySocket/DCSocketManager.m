//
//  DCSocketManager.m
//  HttpBySocket
//
//  Created by boob on 2017/6/15.
//  Copyright © 2017年 YY.COM. All rights reserved.
//

#import <CocoaAsyncSocket/GCDAsyncSocket.h>

#import "DCSocketManager.h"
@interface DCSocketManager()  <GCDAsyncSocketDelegate>
{
    NSString       *_serverHost;//IP或者域名
    int             _serverPort;//端口，https一般是443
    GCDAsyncSocket *_asyncSocket;//一个全局的对象
}
@property (nonatomic, strong) NSMutableData     *sendData;//最终拼接好的需要发送出去的数据
@property (nonatomic, copy)   NSString          *uriString;//具体请求哪个接口，比如https://xxx.xxxxx.com/verificationCode里的verificationCode
@property (nonatomic, strong) NSDictionary      *paramters;//Body里面需要传递的参数
@property (nonatomic, copy)   CompletionHandler  completeHandler;//收到返回数据后的回调Block

@property (nonatomic, strong) NSString * method; //post  get

@property (nonatomic, strong) NSMutableArray *dcNetArr;//网络请求参数的暂存数组，后面会用到
@end

@implementation DCSocketManager
@synthesize serverHost = _serverHost;
@synthesize serverPort = _serverPort;

//Singleton_Implementation(DCSocketManager)//单例

-(NSString *)method{
    if (!_method) {
        _method = @"GET";
    }
    return _method;
}
- (instancetype)init {//对socket进行初始化
    if (self = [super init]) {
        _serverHost = @"106.14.83.31";
        _serverPort = 80;
        _asyncSocket = [[GCDAsyncSocket alloc] initWithDelegate:self delegateQueue:dispatch_get_main_queue() socketQueue:nil];
        _dcNetArr = [NSMutableArray arrayWithCapacity:20];
    }
    return self;
}

#pragma mark GCDAsyncSocketDelegate method

- (void)socketDidDisconnect:(GCDAsyncSocket *)sock withError:(NSError *)err
{//断开连接时会调用
    NSLog(@"didDisconnect...");
    if (self.dcNetArr.count > 0) {
        [_asyncSocket connectToHost:_serverHost onPort:_serverPort error:nil];
    }
}

- (void)socket:(GCDAsyncSocket *)sock didConnectToHost:(NSString *)host port:(uint16_t)port
{//连接上服务器时会调用
    if (self.isHttps) {
        [self doTLSConnect:sock];
        //连接上服务器就要进行tls认证，后面介绍，如果只是http连接就不需要这句
    }
    NSLog(@"didConnectToHost: %@, port: %d", host, port);
    if (self.dcNetArr.count > 0) {
        DCNetCache *net = [self.dcNetArr firstObject];
        self.uriString = net.uri;
        self.paramters = net.params;
        self.completeHandler = net.completeHandler;
        [self.dcNetArr removeObjectAtIndex:0];
    }
    [sock writeData:self.sendData withTimeout:-1 tag:0];//往服务器传递请求数据，之后会介绍self.sendData的拼接
    [sock readDataWithTimeout:-1 tag:0];//马上读取一下
}

- (void)socket:(GCDAsyncSocket *)sock didReadData:(NSData *)data withTag:(long)tag
{//读取到返回数据时会调用
    NSLog(@"didReadData length: %lu, tag: %ld", (unsigned long)data.length, tag);
    if (nil != self.completeHandler) {//如果请求成功，读取到服务器返回的data数据一般是一串字符串，需要根据返回数据格式做相应处理解析出来
        NSString *string = [[NSString alloc] initWithData:data encoding:NSUTF8StringEncoding];
        NSLog(@"\n\nresp: %@\n\n", string);
        NSRange start = [string rangeOfString:@"{"];
//        NSRange end = [string rangeOfString:@"}"];
        NSString *sub;
//        end.location != NSNotFound && 
        if (start.location != NSNotFound) {//如果返回的数据中不包含以上符号，会崩溃
//            sub = [string substringWithRange:NSMakeRange(start.location, end.location-start.location+1)];//这就是服务器返回的body体里的数据
            sub = [string substringFromIndex:start.location];
            NSData *subData = [sub dataUsingEncoding:NSUTF8StringEncoding];;
            NSDictionary *subDic = [NSJSONSerialization JSONObjectWithData:subData options:0 error:nil];
            self.completeHandler(subDic);
        }
    }
    [sock readDataWithTimeout:-1 tag:0];
}

- (void)socket:(GCDAsyncSocket *)sock didWriteDataWithTag:(long)tag
{//成功发送数据时会调用
    NSLog(@"didWriteDataWithTag: %ld", tag);
    [sock readDataWithTimeout:-1 tag:tag];
}

- (void)socketDidSecure:(GCDAsyncSocket *)sock
{//https安全认证成功时会调用
    NSLog(@"SSL握手成功，安全通信已经建立连接!");
}


- (void)doTLSConnect:(GCDAsyncSocket *)sock {
    //HTTPS
    NSMutableDictionary *sslSettings = [[NSMutableDictionary alloc] init];
    NSData *pkcs12data = [[NSData alloc] initWithContentsOfFile:[[NSBundle mainBundle] pathForResource:@"baidu.com" ofType:@"p12"]];//已经支持https的网站会有CA证书，给服务器要一个导出的p12格式证书
    CFDataRef inPKCS12Data = (CFDataRef)CFBridgingRetain(pkcs12data);
    CFStringRef password = CFSTR("xxxxxx");//这里填写上面p12文件的密码
    const void *keys[] = { kSecImportExportPassphrase };
    const void *values[] = { password };
    CFDictionaryRef options = CFDictionaryCreate(NULL, keys, values, 1, NULL, NULL);
    
    CFArrayRef items = CFArrayCreate(NULL, 0, 0, NULL);
    
    OSStatus securityError = SecPKCS12Import(inPKCS12Data, options, &items);
    CFRelease(options);
    CFRelease(password);
    
    if (securityError == errSecSuccess) {
        NSLog(@"Success opening p12 certificate.");
    }
    
    CFDictionaryRef identityDict = CFArrayGetValueAtIndex(items, 0);
    SecIdentityRef myIdent = (SecIdentityRef)CFDictionaryGetValue(identityDict, kSecImportItemIdentity);
    SecIdentityRef  certArray[1] = { myIdent };
    CFArrayRef myCerts = CFArrayCreate(NULL, (void *)certArray, 1, NULL);
    [sslSettings setObject:(id)CFBridgingRelease(myCerts) forKey:(NSString *)kCFStreamSSLCertificates];
    [sslSettings setObject:@"api.pandaworker.com" forKey:(NSString *)kCFStreamSSLPeerName];
    [sock startTLS:sslSettings];//最后调用一下GCDAsyncSocket这个方法进行ssl设置就Ok了
}

- (NSMutableData *)sendData {
    NSMutableData *packetData = [[NSMutableData alloc] init];
    NSData *crlfData = [@"\r\n" dataUsingEncoding:NSUTF8StringEncoding];//回车换行是http协议中每个字段的分隔符
    
    [packetData appendData:[[NSString stringWithFormat:@"%@ /%@ HTTP/1.1",self.method, self.uriString] dataUsingEncoding:NSUTF8StringEncoding]];//拼接的请求行
    [packetData appendData:crlfData];//每个字段后面都要跟一个回车换行
    
    [packetData appendData:[@"Content-Type: application/json; charset=utf-8" dataUsingEncoding:NSUTF8StringEncoding]];//发送数据的格式
    [packetData appendData:crlfData];
    
    [packetData appendData:[@"User-Agent: GCDAsyncSocket8.0" dataUsingEncoding:NSUTF8StringEncoding]];//代理类型，用来识别用户的操作系统及版本等信息，这里我随便填的，一般情况没什么用
    [packetData appendData:crlfData];
    
    [packetData appendData:[[NSString stringWithFormat:@"Host: %@:%d",self.serverHost,self.serverPort] dataUsingEncoding:NSUTF8StringEncoding]];//IP或者域名
    [packetData appendData:crlfData];
    
    NSError *error;
    NSString *bodyString = @"";
    if (self.paramters) {
        NSData *bodyData = [NSJSONSerialization dataWithJSONObject:self.paramters
                                                           options:0
                                                             error:&error];
        bodyString = [[NSString alloc] initWithData:bodyData encoding:NSUTF8StringEncoding];//生成请求体的内容
        [packetData appendData:[[NSString stringWithFormat:@"Content-Length: %ld", bodyString.length] dataUsingEncoding:NSUTF8StringEncoding]];//说明请求体内容的长度
        [packetData appendData:crlfData];
    }
    
    [packetData appendData:[@"Connection:close" dataUsingEncoding:NSUTF8StringEncoding]];
    [packetData appendData:crlfData];
    [packetData appendData:crlfData];//注意这里请求头拼接完成要加两个回车换行
    
    //以上http头信息就拼接完成，下面继续拼接上body信息
    NSString *encodeBodyStr = [NSString stringWithFormat:@"%@\r\n\r\n", @""];//请求体最后也要加上两个回车换行说明数据已经发送完毕
    [packetData appendData:[encodeBodyStr dataUsingEncoding:NSUTF8StringEncoding]];
    
    return packetData;

}


- (void)getRequestUriName:(NSString *)uri Param:(NSDictionary *)params Complete:(CompletionHandler)handler{
    
    NSString * url = [DCNetCache connectUrl:params url:uri];
    DCNetCache *net = [[DCNetCache alloc] initWithUri:url Params:nil CompleteHandler:handler];
    [self.dcNetArr addObject:net];
    NSLog(@"\n\nreq:%@\n\n",url);
    [_asyncSocket connectToHost:_serverHost onPort:_serverPort error:nil];
   
}


- (void)postRequestUriName:(NSString *)uri Param:(NSDictionary *)params Complete:(CompletionHandler)handler{
    
    NSString * url = [DCNetCache connectUrl:params url:uri];
    DCNetCache *net = [[DCNetCache alloc] initWithUri:url Params:nil CompleteHandler:handler];
    [self.dcNetArr addObject:net];
    NSLog(@"\n\nreq:%@\n\n",url);
    self.method = @"POST";
    
    [_asyncSocket connectToHost:_serverHost onPort:_serverPort error:nil];
    
}

@end
