//
//  ZZLiveCell.m
//  LiveTest
//
//  Created by 志方 on 17/3/23.
//  Copyright © 2017年 志方. All rights reserved.
//

#import "ZZLiveCell.h"
#import "ZZLiveModel.h"
#import "ZZCreatorModel.h"
#import <UIImageView+WebCache.h>

@interface ZZLiveCell()

@property (weak, nonatomic) IBOutlet UIImageView *headImageView;
@property (weak, nonatomic) IBOutlet UILabel *nameLabel;
@property (weak, nonatomic) IBOutlet UILabel *addressLabel;
@property (weak, nonatomic) IBOutlet UILabel *chaoyangLabel;
@property (weak, nonatomic) IBOutlet UILabel *liveLabel;

@property (weak, nonatomic) IBOutlet UIImageView *bigPicView;

@end

@implementation ZZLiveCell

-(void)setLive:(ZZLiveModel *)live {
    _live = live;
    NSURL *imageUrl = [NSURL URLWithString:[NSString stringWithFormat:@"%@",live.creator.portrait]];
    [self.headImageView sd_setImageWithURL:imageUrl placeholderImage:nil options:SDWebImageRefreshCached completed:^(UIImage *image, NSError *error, SDImageCacheType cacheType, NSURL *imageURL) {
    }];
    
    if (live.city.length == 0) {
        _addressLabel.text = @"难道在火星";
    }else{
        _addressLabel.text = live.city;
    }
    
    self.nameLabel.text = live.creator.nick;
    
    [self.bigPicView sd_setImageWithURL:imageUrl placeholderImage:nil];
    
    //设置当前观众数量
    NSString *fullChaoyang = [NSString stringWithFormat:@"%zd人在看",live.online_users];
    NSRange range = [fullChaoyang rangeOfString:[NSString stringWithFormat:@"%zd",live.online_users]];
    NSMutableAttributedString *attr = [[NSMutableAttributedString alloc] initWithString:fullChaoyang];
    [attr addAttribute:NSFontAttributeName value:[UIFont systemFontOfSize:17] range:range];
    [attr addAttribute:NSForegroundColorAttributeName value:Color(216, 41, 116) range:range];
    self.chaoyangLabel.attributedText = attr;
}

- (void)awakeFromNib {
    [super awakeFromNib];
    
    _headImageView.layer.cornerRadius = 5;
    _headImageView.layer.masksToBounds = YES;
    
    _liveLabel.layer.cornerRadius = 5;
    _liveLabel.layer.masksToBounds = YES;
    
}

- (void)setSelected:(BOOL)selected animated:(BOOL)animated {
    [super setSelected:selected animated:animated];

    // Configure the view for the selected state
}

@end
