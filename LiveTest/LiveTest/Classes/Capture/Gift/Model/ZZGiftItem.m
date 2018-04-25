//
//  ZZGiftItem.m
//  LiveTest
//
//  Created by 志方 on 17/3/30.
//  Copyright © 2017年 志方. All rights reserved.
//

#import "ZZGiftItem.h"
#import "ZZUserItem.h"

@implementation ZZGiftItem

+ (instancetype)giftWithGiftId:(NSInteger)giftId
                     giftCount:(NSInteger)giftCount
                       roomKey:(NSString *)roomKey
                      giftName:(NSString *)giftName {
    
    ZZGiftItem *item = [[self alloc] init];
    
    item.giftId = giftId;
    item.user = [[ZZUserItem alloc] init];
    
    item.user.ID = @"1";
    item.user.userName = @"用户1";
    item.giftCount = giftCount;
    item.roomKey = roomKey;
    item.giftName = giftName;
    
    return item;
    
}

@end
