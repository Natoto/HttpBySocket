//
//  EcryptHelper.m
//  SDK
//
//  Created by TianJin on 14/11/18.
//  Copyright (c) 2014年 YY. All rights reserved.
//

#import "EcryptHelper.h"
#import <CommonCrypto/CommonCryptor.h>
#import <CommonCrypto/CommonDigest.h>
//#import "LoggerDefines.h"
#import "zlib.h"

@interface bufferHelper : NSObject

@property (nonatomic,assign)uint8_t *buffer;
@property (nonatomic,assign)size_t   size  ;

- (id)init:(NSInteger)size;
- (void)copy:(NSData*)data;

@end
@implementation bufferHelper

- (id)init:(NSInteger)size
{
    self  = [super init];
    
    if (self)
    {
        _buffer = malloc(size);
        _size   = size;
        
        memset((void *)_buffer, 0, size);
    }
    
    return self;
}

- (void)setValue:(uint8_t)value index:(NSInteger)index
{
    _buffer[index] = value;
}

- (void)copy:(NSData*)data
{
    if (data.length > _size) return;
    
    memcpy(_buffer, (const uint8_t *)[data bytes], data.length);
}

- (void)dealloc
{
    if (_buffer != NULL) { free(_buffer); _buffer = NULL; }
}

@end

static const char encodingTable[] = "ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz0123456789+/";

@implementation EcryptHelper

+ (NSString *)toHexString:(NSData*)data
{
    NSMutableString *dest    = [[NSMutableString alloc] initWithString:@""];
    unsigned char   *working = (unsigned char *)[data bytes];
    NSUInteger      srcLen   = [data length];
    
    for (int i = 0; i < srcLen; ++i)
    {
        [dest appendFormat:@"%02x", *working++];
    }
    
    return dest;
}

+ (NSData   *)frHexString:(NSString*)hexString
{
    NSMutableData *data = [[NSMutableData alloc] init];
    NSString       *hex = [hexString uppercaseString];
    
    NSInteger ilen = hex.length / 2;
    NSInteger iidx = 0;
    Byte      b    = 0;
    
    while (iidx < ilen)
    {
        unichar   ch;
        NSInteger i = iidx << 1;
        
        ch = [hex characterAtIndex:i];
        
        if      (ch >= '0' && ch <= '9') b = (ch - '0') << 4;
        else if (ch >= 'a' && ch <= 'f') b = (ch - 'a') << 4;
        
        ch = [hex characterAtIndex:i+1];
        
        if      (ch >= '0' && ch <= '9') b+= (ch - '0');
        else if (ch >= 'a' && ch <= 'f') b+= (ch - 'a');
        
        [data appendBytes:&b length:1];
        
        iidx ++;
    }
    
    return data;
}

+ (NSString *)md5String:(NSString *)strToMD5
{
    return [EcryptHelper toHexString:[EcryptHelper md5FromStri:strToMD5]];
}

+ (NSData   *)md5FromStri:(NSString *)strToMD5
{
    const char    *cStr = [strToMD5 UTF8String];
    unsigned char result[16];
    
    CC_MD5(cStr, (CC_LONG)strlen(cStr), result);
    
    return [NSData dataWithBytes:result length:sizeof(result)];
}

+ (NSData   *)md5FromData:(NSData *)data
{
    unsigned char result[16];
    
    CC_MD5([data bytes], (CC_LONG)[data length], result);
    
    return [NSData dataWithBytes:result length:sizeof(result)];
}

+ (NSData *)dataWithBase64EncodedString:(NSString *)string
{
    if ([string length] == 0  ) return nil;
    
    static char *decodingTable = NULL;
    
    if (decodingTable == NULL)
    {
        decodingTable = malloc(256);
        
        if (decodingTable == NULL) return nil;
        
        memset(decodingTable, CHAR_MAX, 256);

        for (NSUInteger i = 0; i < 64; i++) { decodingTable[(short)encodingTable[i]] = i; }
    }
    
    const char *characters = [string cStringUsingEncoding:NSASCIIStringEncoding];
    
    if (characters == NULL) { return nil; }    //  Not an ASCII string!

    char *bytes = malloc((([string length] + 3) / 4) * 3);
    
    if (bytes      == NULL) { return nil; }
    
    NSUInteger length = 0;
    
    NSUInteger i = 0;
    
    while (YES)
    {
        char  buffer[4];
        short bufferLength;
        
        for (bufferLength = 0; bufferLength < 4; i++)
        {
            if (characters[i] == '\0') { break; }
            if (isspace(characters[i]) || characters[i] == '=') { continue; }
            
            buffer[bufferLength] = decodingTable[(short)characters[i]];
            
            if (buffer[bufferLength++] == CHAR_MAX)      //  Illegal character!
            {
                free(bytes);
                
                return nil;
            }
        }
        
        if (bufferLength == 0) { break; }
        
        if (bufferLength == 1)      //  At least two characters are needed to produce one byte!
        {
            free(bytes);
            return nil;
        }
        
        //  Decode the characters in the buffer to bytes.
        bytes[length++] = (buffer[0] << 2) | (buffer[1] >> 4);
        if (bufferLength > 2) { bytes[length++] = (buffer[1] << 4) | (buffer[2] >> 2); }
        if (bufferLength > 3) { bytes[length++] = (buffer[2] << 6) | buffer[3];        }
    }
    
    bytes = realloc(bytes, length);
    
    return [NSData dataWithBytesNoCopy:bytes length:length];
}

+ (NSString *)base64EncodedStringFrom:(NSData *)data
{
    if ([data length] == 0) { return nil; }
    
    char *characters = malloc((([data length] + 2) / 3) * 4);
    
    if (characters == NULL) { return nil; }
    
    NSUInteger length = 0;
    
    NSUInteger i = 0;
    while (i < [data length])
    {
        char  buffer[3]    = {0, 0, 0};
        short bufferLength = 0;
        
        while (bufferLength < 3 && i < [data length])
        {
            buffer[bufferLength++] = ((char *)[data bytes])[i++];
        }
        
        //  Encode the bytes in the buffer to four characters, including padding "=" characters if necessary.
        characters[length++] = encodingTable[ (buffer[0] & 0xFC) >> 2];
        characters[length++] = encodingTable[((buffer[0] & 0x03) << 4) | ((buffer[1] & 0xF0) >> 4)];
        
        if (bufferLength > 1)
        {
            characters[length++] = encodingTable[((buffer[1] & 0x0F) << 2) | ((buffer[2] & 0xC0) >> 6)];
        }
        else
        {
            characters[length++] = '=';
        }
        
        if (bufferLength > 2)
        {
            characters[length++] = encodingTable[buffer[2] & 0x3F];
        }
        else
        {
            characters[length++] = '=';
        }
    }
    
    return [[NSString alloc] initWithBytesNoCopy:characters length:length encoding:NSASCIIStringEncoding freeWhenDone:YES];
}

//DES------------------------------------------------------------------------------------------------------

+ (NSData *)DESEncrypt:(NSData *)data WithKey:(NSString *)key
{
    char keyPtr[kCCKeySizeAES256+1];
    bzero(keyPtr, sizeof(keyPtr));
    
    [key getCString:keyPtr maxLength:sizeof(keyPtr) encoding:NSUTF8StringEncoding];
    
    NSUInteger dataLength = [data length];
    
    size_t bufferSize = dataLength + kCCBlockSizeAES128;
    void  *buffer = malloc(bufferSize);
    
    size_t numBytesEncrypted = 0;
    CCCryptorStatus cryptStatus = CCCrypt(kCCEncrypt, kCCAlgorithmDES,
                                          kCCOptionPKCS7Padding | kCCOptionECBMode,
                                          keyPtr, kCCBlockSizeDES,
                                          NULL,
                                          [data bytes], dataLength,
                                          buffer, bufferSize,
                                          &numBytesEncrypted);
    if (cryptStatus == kCCSuccess)
    {
        return [NSData dataWithBytesNoCopy:buffer length:numBytesEncrypted];
    }
    
    free(buffer);
    return nil;
}

+ (NSData *)DESDecrypt:(NSData *)data WithKey:(NSString *)key
{
    char keyPtr[kCCKeySizeAES256+1];
    bzero(keyPtr, sizeof(keyPtr));
    
    [key getCString:keyPtr maxLength:sizeof(keyPtr) encoding:NSUTF8StringEncoding];
    
    NSUInteger dataLength = [data length];
    
    size_t bufferSize = dataLength + kCCBlockSizeAES128;
    void *buffer = malloc(bufferSize);
    
    size_t numBytesDecrypted = 0;
    CCCryptorStatus cryptStatus = CCCrypt(kCCDecrypt, kCCAlgorithmDES,
                                          kCCOptionPKCS7Padding | kCCOptionECBMode,
                                          keyPtr, kCCBlockSizeDES,
                                          NULL,
                                          [data bytes], dataLength,
                                          buffer, bufferSize,
                                          &numBytesDecrypted);
    
    if (cryptStatus == kCCSuccess)
    {
        return [NSData dataWithBytesNoCopy:buffer length:numBytesDecrypted];
    }
    
    free(buffer);
    return nil;
}

//RSA------------------------------------------------------------------------------------------------------

+ (SecKeyRef)getKeyRefWithPersistentKeyRef:(CFTypeRef)persistentRef
{
    OSStatus  sanityCheck = noErr;
    SecKeyRef keyRef      = NULL ;

    NSMutableDictionary *queryKey = [[NSMutableDictionary alloc] init];

    [queryKey setObject:(__bridge id)persistentRef forKey:(__bridge id)kSecValuePersistentRef];
    [queryKey setObject:[NSNumber numberWithBool:YES] forKey:(__bridge id)kSecReturnRef];

    sanityCheck = SecItemCopyMatching((__bridge CFDictionaryRef)queryKey, (CFTypeRef *)&keyRef);
    
    if (sanityCheck != noErr) { keyRef = NULL; NSLog(@"KeyChain err1:%d", (int)sanityCheck); }
    
    return keyRef;
}

+ (SecKeyRef)addPublicKey:(NSString *)keyName keyBits:(NSData *)publicKey
{
    NSAssert(keyName   != nil, @"Key name parameter is nil."  );
    NSAssert(publicKey != nil, @"Public key parameter is nil.");
    if (keyName == nil || publicKey == nil) return nil;
    
    OSStatus  sanityCheck= noErr;
    SecKeyRef peerKeyRef = NULL;
    CFTypeRef persistPeer= NULL;
    
    NSData              *keyTag            = [[NSData alloc] initWithBytes:(const void *)[keyName UTF8String] length:[keyName length]];
    NSMutableDictionary *peerPublicKeyAttr = [[NSMutableDictionary alloc] init];
    
    [peerPublicKeyAttr setObject:(__bridge id)kSecClassKey forKey:(__bridge id)kSecClass];
    [peerPublicKeyAttr setObject:(__bridge id)kSecAttrKeyTypeRSA forKey:(__bridge id)kSecAttrKeyType];
    [peerPublicKeyAttr setObject:keyTag forKey:(__bridge id)kSecAttrApplicationTag];
    [peerPublicKeyAttr setObject:publicKey forKey:(__bridge id)kSecValueData];
    [peerPublicKeyAttr setObject:[NSNumber numberWithBool:YES] forKey:(__bridge id)kSecReturnPersistentRef];
    
    sanityCheck = SecItemAdd((__bridge CFDictionaryRef) peerPublicKeyAttr, (CFTypeRef *)&persistPeer);
    
    if (persistPeer)
    {
        peerKeyRef = [EcryptHelper getKeyRefWithPersistentKeyRef:persistPeer];
    }
    else
    {
        [peerPublicKeyAttr removeObjectForKey:(__bridge id)kSecReturnPersistentRef];
        [peerPublicKeyAttr removeObjectForKey:(__bridge id)kSecValueData          ];
        [peerPublicKeyAttr setObject:[NSNumber numberWithBool:YES] forKey:(__bridge id)kSecReturnRef];
        
        sanityCheck = SecItemCopyMatching((__bridge CFDictionaryRef)peerPublicKeyAttr, (CFTypeRef *)&peerKeyRef);
        
        if (sanityCheck != noErr) { peerKeyRef = NULL; NSLog(@"KeyChain err2:%d", (int)sanityCheck); }
    }
    
    if (persistPeer) { CFRelease(persistPeer); }
    
    return peerKeyRef;
}

+ (void)removePublicKey:(NSString *)keyName
{
    NSAssert( keyName != nil, @"Peer name parameter is nil." );
    if (keyName == nil) return;
    
    OSStatus sanityCheck = noErr;
    
    NSData              *peerTag           = [[NSData alloc] initWithBytes:(const void *)[keyName UTF8String] length:[keyName length]];
    NSMutableDictionary *peerPublicKeyAttr = [[NSMutableDictionary alloc] init];
    
    [peerPublicKeyAttr setObject:(__bridge id)kSecClassKey forKey:(__bridge id)kSecClass];
    [peerPublicKeyAttr setObject:(__bridge id)kSecAttrKeyTypeRSA forKey:(__bridge id)kSecAttrKeyType];
    [peerPublicKeyAttr setObject:peerTag forKey:(__bridge id)kSecAttrApplicationTag];
    
    sanityCheck = SecItemDelete((__bridge CFDictionaryRef) peerPublicKeyAttr);
}

+ (NSData *)stripPublicKeyHeader:(NSData *)keyData
{
    if (0 == [keyData length])                { return nil; }
    
    unsigned char *keyBytes = (unsigned char *)[keyData bytes];
    unsigned int  index    = 0;
    
    if (keyBytes[index++] != 0x30)            { return nil; }
    
    if (keyBytes[index] > 0x80)               { index += keyBytes[index] - 0x80 + 1; }
    else                                      { index++; }
    
    // PKCS #1 rsaEncryption szOID_RSA_RSA
    static unsigned char seqiod[] = { 0x30, 0x0d, 0x06, 0x09, 0x2a,
                                      0x86, 0x48, 0x86, 0xf7, 0x0d,
                                      0x01, 0x01, 0x01, 0x05, 0x00 };
    
    if (memcmp(&keyBytes[index], seqiod, 15)) { return nil; }
    
    index += 15;
    
    if (keyBytes[index++] != 0x03)            { return nil; }
    
    if (keyBytes[index]    > 0x80)            { index += keyBytes[index] - 0x80 + 1; }
    else                                      { index++; }
    
    if (keyBytes[index++] != '\0')            { return nil; }
    
    // Now make a new NSData from this buffer
    return([NSData dataWithBytes:&keyBytes[index] length:[keyData length] - index]);
}

+ (NSData   *)dataFromBase64String:(NSString*)Base64
{
    return [EcryptHelper dataWithBase64EncodedString:Base64];
    
    //这里5.0 不支持 顾不能使用
    //return [[NSData alloc] initWithBase64EncodedString:Base64 options:NSDataBase64DecodingIgnoreUnknownCharacters];
}

+ (SecKeyRef)addPublicKey:(NSString*)keyName keyString:(NSString*)keyStringBase64
{
    NSData    *publicKey = [EcryptHelper stripPublicKeyHeader:[EcryptHelper dataFromBase64String:keyStringBase64]];
    SecKeyRef key        = [EcryptHelper addPublicKey:keyName keyBits:publicKey];

    [EcryptHelper removePublicKey:keyName];
    
    return key;
}

+ (NSData *)RSAEncryptData:(NSData *)plainData Key:(SecKeyRef)publicKey
{
    size_t     cipherBufferSize = SecKeyGetBlockSize(publicKey);
    //NSData    *plainTextBytes   = [plainText dataUsingEncoding:NSUTF8StringEncoding];
    int        blockSize        = (int)cipherBufferSize - 11;
    int        numBlock         = (int)ceil([plainData length] / (double)blockSize);
    NSUInteger iDataLen         = plainData.length;
    int        fAddValue        = 0;
    
    if (iDataLen % blockSize) { fAddValue = 1; iDataLen += blockSize - plainData.length % blockSize; }
    
    bufferHelper *cipher        = [[bufferHelper alloc] init:cipherBufferSize * sizeof(uint8_t)];
    bufferHelper *plain         = [[bufferHelper alloc] init:iDataLen         * sizeof(uint8_t)];
    
    [plain copy:plainData];
    
    if (fAddValue)            { [plain setValue:(blockSize - plainData.length % blockSize) index:(iDataLen - 1)]; }
    
    NSMutableData *encryptedData = [[NSMutableData alloc] init];
    for (int i = 0; i < numBlock; i++)
    {
        OSStatus status  = SecKeyEncrypt(publicKey          ,
                                         kSecPaddingPKCS1   ,
                                         plain.buffer       ,
                                         plain.size         ,
                                         cipher.buffer,
                                         &cipherBufferSize );
        
        if (status != noErr) { return nil; }
       
        NSData *encryptedBytes = [[NSData alloc] initWithBytes:(const void *)cipher.buffer
                                                        length:cipherBufferSize];
        
        [encryptedData appendData:encryptedBytes];
    }
    
    return encryptedData;
}

//获取私钥时有点问题
+ (NSData *)RSADecryptData:(NSData *)cipherData Key:(SecKeyRef)publicKey
{
    // 分配内存块，用于存放解密后的数据段
    size_t plainBufferSize = SecKeyGetBlockSize(publicKey);
    double totalLength     = [cipherData length];
    size_t blockSize       = plainBufferSize;
    size_t blockCount      = (size_t)ceil(totalLength / blockSize);
    NSMutableData *decryptedData = [NSMutableData data];
    
    bufferHelper *plain        = [[bufferHelper alloc] init:plainBufferSize * sizeof(uint8_t)];
    
    // 分段解密
    for (int i = 0; i < blockCount; i++)
    {
        NSUInteger loc = i * blockSize;
        
        int dataSegmentRealSize = MIN(blockSize, totalLength - loc);
        NSData *dataSegment     = [cipherData subdataWithRange:NSMakeRange(loc, dataSegmentRealSize)];
        OSStatus status         = SecKeyDecrypt(publicKey, kSecPaddingPKCS1, (const uint8_t *)[dataSegment bytes],
                                                dataSegmentRealSize, plain.buffer, &plainBufferSize);
        
        if (status == errSecSuccess)
        {
            NSData *decryptedDataSegment = [[NSData alloc] initWithBytes:plain.buffer length:plainBufferSize];
            [decryptedData appendData:decryptedDataSegment];
        }
        else
        {
            return nil;
        }
    }
    
    return decryptedData;
}

//AES------------------------------------------------------------------------------------

+ (NSData *)AES128:(CCOperation)operation key:(NSString *)key data:(NSData*)data
{
    NSData     *pdkey     = [EcryptHelper md5FromStri:key];
    
    char keyPtr[kCCKeySizeAES128 + 1];
    memset(keyPtr, 0, sizeof(keyPtr));
    memcpy(keyPtr, [pdkey bytes], pdkey.length);
    
    char ivPtr [kCCKeySizeAES128 + 1];
    memset(ivPtr , 0, sizeof(ivPtr ));
    memcpy(ivPtr , [pdkey bytes], pdkey.length);

    NSUInteger dataLength = [data length];
    
    int dataPtrSize = (int)dataLength;
    int diff        = 0;
    
    if (operation == kCCEncrypt)
    {
        diff = (kCCKeySizeAES128 - (dataLength % kCCKeySizeAES128)) % kCCKeySizeAES128;
        if (diff > 0) { dataPtrSize += diff; }
    }
    
    char dataPtr[dataPtrSize];
    memcpy(dataPtr, [data bytes], [data length]);
    for (int i = 0; i < diff; i++) { dataPtr[i + dataLength] = 0x00; }
    
    size_t bufferSize = dataPtrSize + kCCBlockSizeAES128;
    void  *buffer = malloc(bufferSize);
    memset(buffer, 0, bufferSize);
    
    size_t numBytesCrypted = 0;
    
    CCCryptorStatus cryptStatus = CCCrypt(operation,
                                          kCCAlgorithmAES128,
                                          0x0000,               //No padding
                                          keyPtr,
                                          kCCKeySizeAES128,
                                          ivPtr,
                                          dataPtr,
                                          dataPtrSize,
                                          buffer,
                                          bufferSize,
                                          &numBytesCrypted);
    
    if (cryptStatus == kCCSuccess)
    {
        return [NSData dataWithBytesNoCopy:buffer length:numBytesCrypted];
    }
    
    free(buffer);
    
    return nil;
}

+ (NSData *)AES128EncryptWithKey:(NSString *)key data:(NSData*)data  //加密
{
    return [EcryptHelper AES128:kCCEncrypt key:key data:data];
}

+ (NSString *)stringByFormURLEncoding:(NSString *)aString
{
    if ([aString length] == 0) { return @""; }
    
    CFStringRef originalString = (__bridge  CFStringRef)aString;
    CFStringRef encodedString  =
    CFURLCreateStringByAddingPercentEscapes(kCFAllocatorDefault,
                                            originalString,
                                            NULL,
                                            CFSTR("+:/?#[]@!$&'()*,;=\r\n"),
                                            kCFStringEncodingUTF8
                                            );
    
    return (NSString *)CFBridgingRelease(encodedString);
}

+ (bool)setKeyChain:(NSString*)key Data:(NSData*)data
{
    OSStatus sanityCheck = noErr;
    
    NSData              *keyTag   = [[NSData alloc] initWithBytes:(const void *)[key UTF8String] length:[key length]];
    NSMutableDictionary *queryKey = [NSMutableDictionary dictionaryWithObjectsAndKeys:
                                     (__bridge id)kSecClassKey    , (__bridge id)kSecClass,
                                     keyTag                       , (__bridge id)kSecAttrApplicationTag,
                                     data                         , (__bridge id)kSecValueData,
                                     nil];
    
    sanityCheck = SecItemAdd((__bridge CFDictionaryRef)queryKey, nil);
    
    if (sanityCheck != noErr) { return false; }
    
    return true;
}

+ (bool   )updKeyChain:(NSString*)key Data:(NSData*)data
{
    OSStatus sanityCheck = noErr;
    
    NSData              *keyTag   = [[NSData alloc] initWithBytes:(const void *)[key UTF8String] length:[key length]];
    NSMutableDictionary *queryKey = [NSMutableDictionary dictionaryWithObjectsAndKeys:
                                     (__bridge id)kSecClassKey    , (__bridge id)kSecClass,
                                     keyTag                       , (__bridge id)kSecAttrApplicationTag,
                                     nil];
    
    NSMutableDictionary *queryKey1 = [NSMutableDictionary dictionaryWithObjectsAndKeys:
                                     data                         , (__bridge id)kSecValueData,
                                     nil];
    
    sanityCheck = SecItemUpdate((__bridge CFDictionaryRef)queryKey, (__bridge CFDictionaryRef)queryKey1);
    
    if (sanityCheck != noErr) { return false; }
    
    return true;
}

+ (NSData*)getKeyChain:(NSString*)key
{
    OSStatus  sanityCheck = noErr;
    CFDataRef keyRef      = NULL ;
    
    NSData              *keyTag   = [[NSData alloc] initWithBytes:(const void *)[key UTF8String] length:[key length]];
    NSMutableDictionary *queryKey = [NSMutableDictionary dictionaryWithObjectsAndKeys:
                                     (__bridge id)kSecClassKey    , (__bridge id)kSecClass,
                                     keyTag                       , (__bridge id)kSecAttrApplicationTag,
                                     [NSNumber numberWithBool:YES], (__bridge id)kSecReturnData,
                                     nil];
    
    sanityCheck = SecItemCopyMatching((__bridge CFDictionaryRef)queryKey, (CFTypeRef *)&keyRef);
    
    if (sanityCheck != noErr) { return nil; }
    
    NSData *ret = [[NSData alloc] initWithData:(__bridge NSData *)keyRef];
    
    CFRelease(keyRef);
    
    return ret;
}

+ (bool)delKeyChain:(NSString*)key
{
    OSStatus  sanityCheck = noErr;
    
    NSData              *keyTag   = [[NSData alloc] initWithBytes:(const void *)[key UTF8String] length:[key length]];
    NSMutableDictionary *queryKey = [NSMutableDictionary dictionaryWithObjectsAndKeys:
                                     (__bridge id)kSecClassKey    , (__bridge id)kSecClass,
                                     keyTag                       , (__bridge id)kSecAttrApplicationTag,
                                     nil];
    
    sanityCheck = SecItemDelete((__bridge CFDictionaryRef)queryKey);
    
    if (sanityCheck != noErr) { return false; }

    return true;
}

+ (NSString*)getUserData:(NSString*)key
{
    NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];
    NSData         *data     = [defaults objectForKey:key];
    NSString       *str      = nil;
    
    if (data == nil) return nil;
    
    @try
    {
        NSDictionary *dict = [NSKeyedUnarchiver unarchiveObjectWithData:data];
        NSArray      *ary  = [dict allKeys];
        
        if (ary  == nil) return nil;
        
        NSString *strMD5 = [ary  objectAtIndex:0];
        NSString *strdat = [dict objectForKey:strMD5];
        NSString *nowMD5 = [EcryptHelper md5String:[NSString stringWithFormat:@"%@HiidoUDID", strdat]];
        
        if ([nowMD5 compare:strMD5] == NSOrderedSame)
        {
            str = strdat;
        }
    }
    @catch (NSException *exception)
    {
        [EcryptHelper delUserData:key];
    }
    @finally
    {
        
    }
    
    return str;
}

+ (void)delUserData:(NSString*)key
{
    NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];
    
    [defaults removeObjectForKey:key];
}

+ (BOOL)setUserData:(NSString*)key data:(NSString*)data
{
    if ([key isKindOfClass:[NSString class]] == NO || [data isKindOfClass:[NSString class]] == NO) return NO;
    
    NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];
    NSString         *strMD5 = [EcryptHelper md5String:[NSString stringWithFormat:@"%@HiidoUDID", data]];
    NSDictionary        *dic = @{strMD5:data};
    NSData           *svdata = [NSKeyedArchiver archivedDataWithRootObject:dic];
    
    [defaults setObject:svdata forKey:key];
    
    [defaults synchronize];
    
    return YES;
}

+ (NSData*)zip:(NSData*)data
{
    z_stream strm;
    
    strm.next_in  = (Bytef *)[data bytes];
    strm.avail_in = (uInt)[data length];
    strm.zalloc   = Z_NULL;
    strm.zfree    = Z_NULL;
    strm.opaque   = Z_NULL;
    
    int status = deflateInit(&strm, Z_BEST_COMPRESSION);
    
    NSMutableData *compressedData = [NSMutableData dataWithLength:[data length] * 1.01 + 12];
    
    do
    {
        strm.next_out  = (Bytef *)[compressedData mutableBytes] +       strm.total_out;
        strm.avail_out = (uInt   )[compressedData length      ] - (uInt)strm.total_out;
        
        status = deflate(&strm, Z_FINISH);
        
    } while ( status == Z_OK );
    
    deflateEnd(&strm);
    
    [compressedData setLength:strm.total_out];
    
    return compressedData;
}

+ (NSData*)unzip:(NSData*)data
{
    z_stream strm;
    
    strm.next_in  = (Bytef *)[data bytes];
    strm.avail_in = (uInt)[data length];
    strm.zalloc   = Z_NULL;
    strm.zfree    = Z_NULL;
    strm.opaque   = Z_NULL;
    
    unsigned full_length = (int)[data length];
    unsigned half_length = (int)[data length] / 2;
    
    if (inflateInit2(&strm, (15 + 32)) != Z_OK) return nil;
    
    NSMutableData *decompressed = [NSMutableData dataWithLength:full_length + half_length];
    
    int status;
    do
    {
        if (strm.total_out >= [decompressed length]) { [decompressed increaseLengthBy: half_length]; }
        
        strm.next_out  = (Bytef *)[decompressed mutableBytes] +       strm.total_out;
        strm.avail_out = (uInt   )[decompressed length      ] - (uInt)strm.total_out;
        
        status         = inflate(&strm, Z_SYNC_FLUSH);
        
    } while (status == Z_OK);
    
    if (inflateEnd (&strm) != Z_OK) return nil;
    
    [decompressed setLength:strm.total_out];
    
    return decompressed;
}

+ (unsigned long)crc32:(const char*)buf Len:(uint)len
{
    return crc32(0, (Bytef*)buf, len);
}

+ (BOOL)archiveRootObject:(id)rootObject toFile:(NSString *)path
{
    BOOL ret = FALSE;
    
    if (rootObject == nil || path == nil) return ret;
    
    @try
    {
        ret = [NSKeyedArchiver archiveRootObject:rootObject toFile:path];
    }
    @catch (NSException *exception)
    {
        NSLog(@"archiveRootObject Err:%@ ", exception);
    }
    @finally
    {
        
    }
    
    return ret;
}

+ (id)unarchiveObjectWithFile:(NSString*)FullPaths
{
    id dict = nil;
    
    if (FullPaths == nil) return nil;
    
    @try
    {
        dict = [NSKeyedUnarchiver unarchiveObjectWithFile:FullPaths];
    }
    @catch (NSException *exception)
    {
        [[NSFileManager defaultManager] removeItemAtPath:FullPaths error:nil];
    }
    @finally
    {
        
    }
    
    return dict;
}

+ (NSData*)archivedDataWithRootObject:(id)rootObject
{
    NSData *ret = nil;
    
    if (rootObject == nil) return nil;
    
    @try
    {
        ret = [NSKeyedArchiver archivedDataWithRootObject:rootObject];
    }
    @catch (NSException *exception)
    {
        NSLog(@"archivedDataWithRootObject Err:%@ ", exception);
    }
    @finally
    {
        
    }
    
    return ret;
}

+ (id)unarchiveObjectWithData:(NSData*)data
{
    id obj = nil;
    
    if (data == nil) return nil;
    
    @try
    {
        obj = [NSKeyedUnarchiver unarchiveObjectWithData:data];
    }
    @catch (NSException *exception)
    {
        NSLog(@"unarchiveObjectWithData Err:%@ ", exception);
    }
    @finally
    {
        
    }
    
    return obj;
}

@end
