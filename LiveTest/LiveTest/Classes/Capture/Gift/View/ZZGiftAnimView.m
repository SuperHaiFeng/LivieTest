//
//  ZZGiftAnimView.m
//  LiveTest
//
//  Created by 志方 on 17/3/30.
//  Copyright © 2017年 志方. All rights reserved.
//

#import "ZZGiftAnimView.h"

@implementation ZZGiftAnimView

+(instancetype)giftAnimView {
    static ZZGiftAnimView *giftView = nil;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        giftView = [[ZZGiftAnimView alloc] init];
    });
    return giftView;
}
-(instancetype)init {
    self = [super init];
    if (self) {
        self.alpha = 0;
        self.imageView = [[UIImageView alloc] initWithFrame:self.frame];
        self.imageView.backgroundColor = [UIColor grayColor];
        [self addSubview:self.imageView];
    }
    
    return self;
}

/*
// Only override drawRect: if you perform custom drawing.
// An empty implementation adversely affects performance during animation.
- (void)drawRect:(CGRect)rect {
    // Drawing code
}
*/

@end
