//
//  ZZLiveController.m
//  LiveTest
//
//  Created by 志方 on 17/3/23.
//  Copyright © 2017年 志方. All rights reserved.
//

#import "ZZLiveController.h"
#import <IJKMediaFramework/IJKMediaFramework.h>
#import "ZZLiveModel.h"
#import "ZZCreatorModel.h"
#import <UIImageView+WebCache.h>
#import "UIImage+blur.h"
#import <AVFoundation/AVFoundation.h>

@interface ZZLiveController ()

@property(nonatomic,strong) UIImageView *imageView;
@property(nonatomic,strong) IJKFFMoviePlayerController *player;
@property(nonatomic,strong) UIButton *backBtn;

@end

@implementation ZZLiveController

- (void)viewDidLoad {
    [super viewDidLoad];
    self.view.backgroundColor = [UIColor whiteColor];
    [self.navigationController.navigationBar setHidden:YES];
    
    self.backBtn = [UIButton buttonWithType:UIButtonTypeSystem];
    self.backBtn.frame = CGRectMake(10, 25, 40, 40);
    [self.backBtn setTitle:@"<" forState:UIControlStateNormal];
    [self.backBtn setTintColor:[UIColor whiteColor]];
    self.backBtn.titleLabel.font = [UIFont boldSystemFontOfSize:20];
    self.backBtn.layer.cornerRadius = 20;
    self.backBtn.backgroundColor = Color(216, 41, 116);
    self.backBtn.alpha = 0.8;
    [self.backBtn addTarget:self action:@selector(backAction) forControlEvents:UIControlEventTouchUpInside];
    
    
    self.imageView = [[UIImageView alloc] initWithFrame:CGRectMake(0, 0, [UIScreen mainScreen].bounds.size.width, [UIScreen mainScreen].bounds.size.height)];
    [self.view addSubview:self.imageView];
    
    //设置站位图片
    NSURL *imageUrl = [NSURL URLWithString:[NSString stringWithFormat:@"%@",_live.creator.portrait]];
//    UIImage *image = [UIImage imageWithData:[NSData dataWithContentsOfURL:imageUrl]];
//    self.imageView.image = [UIImage boxblurImage:image withBlurNumber:0.5];
    
    [self.imageView sd_setImageWithURL:imageUrl placeholderImage:nil];
    /** ios7给图片设置磨玻璃效果 */
    UIToolbar *toolbar = [[UIToolbar alloc] initWithFrame:CGRectMake(0, 0, self.imageView.frame.size.width, self.imageView.frame.size.height)];
    toolbar.barStyle = UIBarStyleBlackTranslucent;
    [self.imageView addSubview:toolbar];
    
    
    /** ios8之后出现 */
    /**
    UIBlurEffect *effect = [UIBlurEffect effectWithStyle:UIBlurEffectStyleDark];
    UIVisualEffectView *effectView = [[UIVisualEffectView alloc] initWithEffect:effect];
    effectView.frame = CGRectMake(0, 0, self.imageView.frame.size.width, self.imageView.frame.size.height);
    [self.imageView addSubview:effectView];
     
     */
    
    
    //拉流地址
    NSURL *url = [NSURL URLWithString:_live.stream_addr];
    
    //创建 IJKFFMoviePlayerController 专门用来直播,传入拉流地址就好了
    IJKFFMoviePlayerController *playerVC = [[IJKFFMoviePlayerController alloc] initWithContentURL:url withOptions:nil];
    [playerVC.view addSubview:self.backBtn];
    //准备播放
    [playerVC prepareToPlay];
    
    //强引用，反正被销毁
    _player = playerVC;
    
    playerVC.view.frame = [UIScreen mainScreen].bounds;
    [self.view insertSubview:playerVC.view atIndex:1];
}
-(void) backAction {
    [self.navigationController popViewControllerAnimated:YES];
}

-(void)viewWillDisappear:(BOOL)animated {
    [super viewWillDisappear:animated];
    
    //界面消失，一定停止播放，否则会产生内存泄露
    [_player pause];
    [_player stop];
    [_player shutdown];
    
}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

/*
#pragma mark - Navigation

// In a storyboard-based application, you will often want to do a little preparation before navigation
- (void)prepareForSegue:(UIStoryboardSegue *)segue sender:(id)sender {
    // Get the new view controller using [segue destinationViewController].
    // Pass the selected object to the new view controller.
}
*/

@end
