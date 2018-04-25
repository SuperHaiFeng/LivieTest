//
//  ZZGiftItem.h
//  LiveTest
//
//  Created by 志方 on 17/3/30.
//  Copyright © 2017年 志方. All rights reserved.
//

#import <Foundation/Foundation.h>

@class ZZUserItem;
@interface ZZGiftItem : NSObject

//礼物id
@property(nonatomic, assign) NSInteger giftId;

//用户模型：记录哪个用户发送
@property(nonatomic, strong) ZZUserItem *user;

//礼物名称
@property(nonatomic, strong) NSString *giftName;

//礼物个数，用来记录礼物的连击数
@property(nonatomic, assign) NSInteger giftCount;

//发送哪个房间
@property(nonatomic, strong) NSString *roomKey;

+ (instancetype)giftWithGiftId:(NSInteger)giftId
                     giftCount:(NSInteger)giftCount
                       roomKey:(NSString *)roomKey
                      giftName:(NSString *)giftName;


@end
