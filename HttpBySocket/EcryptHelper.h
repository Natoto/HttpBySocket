//
//  EcryptHelper.h
//  HiidoSDK
//
//  Created by TianJin on 14/11/18.
//  Copyright (c) 2014年 YY. All rights reserved.
//
#import <Foundation/Foundation.h>

@interface EcryptHelper : NSObject

//md5
+ (NSString *)md5String  :(NSString *)strToMD5;
+ (NSData   *)md5FromStri:(NSString *)strToMD5;
+ (NSData   *)md5FromData:(NSData *)data;

//
+ (NSString *)toHexString:(NSData *)data;
+ (NSData   *)frHexString:(NSString*)hexString;

//b64
+ (NSString *)base64EncodedStringFrom:(NSData *)data;
+ (NSData   *)dataWithBase64EncodedString:(NSString *)string;

//url
+ (NSString *)stringByFormURLEncoding:(NSString *)aString;

//DES----------------------------------------------------------
+ (NSData   *)DESEncrypt:(NSData *)data WithKey:(NSString *)key;
+ (NSData   *)DESDecrypt:(NSData *)data WithKey:(NSString *)key;

//RSA----------------------------------------------------------
+ (SecKeyRef )addPublicKey:(NSString*)keyName keyString:(NSString*)keyStringBase64;
+ (NSData   *)RSAEncryptData:(NSData *)plainData  Key:(SecKeyRef)publicKey;
+ (NSData   *)RSADecryptData:(NSData *)cipherData Key:(SecKeyRef)publicKey;

//AES----------------------------------------------------------
+ (NSData   *)AES128EncryptWithKey:(NSString *)key data:(NSData*)data; //加密

+ (bool   )setKeyChain:(NSString*)key Data:(NSData*)data;
+ (bool   )updKeyChain:(NSString*)key Data:(NSData*)data;
+ (NSData*)getKeyChain:(NSString*)key;
+ (bool   )delKeyChain:(NSString*)key;

+ (NSString*)getUserData:(NSString*)key;
+ (BOOL   )setUserData:(NSString*)key data:(NSString*)data;

+ (NSData*)zip  :(NSData*)data;
+ (NSData*)unzip:(NSData*)data;
+ (unsigned long)crc32:(const char*)buf Len:(uint)len;

+ (id)unarchiveObjectWithFile:(NSString*)FullPaths;
+ (id)unarchiveObjectWithData:(NSData*)data;
+ (NSData*)archivedDataWithRootObject:(id)rootObject;
+ (BOOL)archiveRootObject:(id)rootObject toFile:(NSString *)path;

@end
