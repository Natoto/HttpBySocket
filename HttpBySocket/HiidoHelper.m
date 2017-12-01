
//
//  HiidoHelper.m
//  HttpBySocket
//
//  Created by boob on 2017/6/29.
//  Copyright © 2017年 YY.COM. All rights reserved.
//

#import "HiidoHelper.h"
#import "EcryptHelper.h"

@implementation HiidoParamObject
- (instancetype)init
{
    self = [super init];
    if (self) {
    }
    return self;
}
@end

@interface HiidoHelper()


@end

@implementation HiidoHelper


#undef DEF_RSAKeyData
#define  DEF_RSAKeyData @"MCwwDQYJKoZIhvcNAQEBBQADGwAwGAIRAMRSvSVZEbyQwtFwNtNiZKkCAwEAAQ=="

/**
 * 根据组合的参数，解包获得body和其他参数
 * reqData 如下：
 act=mbsdkevent&hdid=e097eaa18a950e241206a609a7983c738f5d16b7&opid=e097eaa18a950e241206a609a7983c738f5d16b7&mac=e097eaa18a950e241206a609a7983c738f5d16b7&idfa=5E1A5D3E-4325-456C-8675-62F5B6940BB4&net=3&from=fromMyDemo&time=1498725561&key=32678678ca2c5d4c1dd70675bc39a4c5&sys=0&app=com.juhui.sdkdemo&imei=e097eaa18a950e241206a609a7983c738f5d16b7&ver=1.32&sdkver=3.1.91&appkey=6ffb6db7c211b966b735f07c16176f7f&guid=A09E2B01-F63B-42C5-9CCD-D6CF9148DD49&sessionid=b800afc599d12aebf5c7ccf73d563238&idfv=13B57757-665C-49EA-A453-3EA00D001FDE&uid=123456&event=0202%3A1%3A1%3A0001%3A

 */
+(HiidoParamObject *)getSmdecryptString:(NSString *)reqData{
 
   NSString * _appKeyName = @"hiidodemo"; //[ComUtils     getAppKeyName:appKey];
   NSString * kSDKName = @"HDANA";
   NSString * _rasKeyName = [EcryptHelper md5String:[NSString stringWithFormat:@"%@RSAKey_Hiido*&^%@", kSDKName, _appKeyName]];

   SecKeyRef  _SecKeyRef = [EcryptHelper addPublicKey:_rasKeyName keyString:DEF_RSAKeyData];
    
    NSInteger iData   = reqData.length;
    NSString  *appkey = [[self class] subStringByKey:@"appkey" reqData:reqData];
    NSString  *item   = [[self class] subStringByKey:@"act"    reqData:reqData];
    
    //开始加密
    NSInteger nsii    = arc4random();
    NSString *AESkey  = [NSString stringWithFormat:@"%02x%02x", (unsigned char)(nsii&0xff), (unsigned char)((nsii >> 8)&0xff)];
    NSData   *keydata = [EcryptHelper RSAEncryptData:[AESkey dataUsingEncoding:NSUTF8StringEncoding] Key:_SecKeyRef];
    NSData   *AESData = [EcryptHelper AES128EncryptWithKey:AESkey data:[reqData dataUsingEncoding:NSUTF8StringEncoding]];
    NSString *smkdata = [NSString stringWithFormat:@"%08lu%@", (unsigned long)AESkey.length, [EcryptHelper toHexString:keydata]];
    
//    _strSmk  = smkdata;
    
    NSString * newreqdata  = [EcryptHelper base64EncodedStringFrom:AESData];
    
    HiidoParamObject * obj = [[HiidoParamObject alloc] init];
    obj.base64ReqBody = newreqdata;
    obj.iData = iData;
    obj.appkey = appkey;
    obj.item = item;
    obj.smkdata = smkdata;
    
    return obj;

}

/**
 * 生成以下链接：
 act=mbsdkdata&smkdata=00000004035b5f7bda1b1c40d9f1fed3f33705ac&EC=0&appkey=6ffb6db7c211b966b735f07c16176f7f&enc=b64&item=mbsdkevent
 */
+(NSString * )getrequeststr:(NSString *)strPath param:(HiidoParamObject *)obj{

    // base64ReqBody:(NSString *)reqData Host:(NSString *)Host iData:(NSInteger)iData
    NSString *headFrmt= @"%@?act=mbsdkdata&smkdata=%@&EC=%ld&appkey=%@&enc=b64&item=%@";
    NSString *reqHead = [NSString stringWithFormat:headFrmt, strPath, obj.smkdata, 0, obj.appkey, obj.item];
    //TODO: 这里生成POST GET URL
//    NSString * requestStrFrmt = @"POST %@ HTTP/1.1\r\nHost: %@ \r\nAccept: text/html\r\nContent-Length: %ld\r\n\r\n%08ld%@";
//    NSString * requestStr     = [NSString stringWithFormat:requestStrFrmt, reqHead, Host, reqData.length + 8, iData, reqData];
    return reqHead;
}

+ (NSString*)subStringByKey:(NSString*)key reqData:(NSString*)reqData
{
    NSInteger iData = reqData.length;
    NSRange   range0, range1;
    
    range0 = [reqData rangeOfString:[NSString stringWithFormat:@"%@=", key]];
    
    if (range0.location != NSNotFound)
    {
        range0.location += range0.length;
        range0.length    = iData - range0.location;
        
        if (range0.length > 0)
        {
            range1       = [reqData rangeOfString:@"&" options:0 range:range0];
            
            if (range1.location != NSNotFound)
            {
                range0.length= range1.location - range0.location;
                
                if (range0.length > 0)
                {
                    return [reqData substringWithRange:range0];
                }
            }
            else
            {
                return [reqData substringWithRange:range0];
            }
        }
    }
    
    return @"";
}


@end
