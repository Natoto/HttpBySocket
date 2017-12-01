//
//  HiidoHelper.h
//  HttpBySocket
//
//  Created by boob on 2017/6/29.
//  Copyright © 2017年 YY.COM. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface HiidoParamObject : NSObject

@property (nonatomic, strong) NSString * base64ReqBody;
@property (nonatomic, assign) NSInteger  iData;
@property (nonatomic, strong) NSString * appkey;
@property (nonatomic, strong) NSString * item;
@property (nonatomic, strong) NSString * keydata;
@property (nonatomic, strong) NSString * smkdata;

@end



@interface HiidoHelper : NSObject

+ (NSString*)subStringByKey:(NSString*)key reqData:(NSString*)reqData;

+(HiidoParamObject *)getSmdecryptString:(NSString *)reqData;

+(NSString * )getrequeststr:(NSString *)strPath param:(HiidoParamObject *)obj;

@end
