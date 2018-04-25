//
//  ImageVC.m
//  LiveTest
//
//  Created by 志方 on 17/3/28.
//  Copyright © 2017年 志方. All rights reserved.
//

#import "ImageVC.h"
#import "GPUImageBeautifyFilter.h"

@interface ImageVC ()

@property(nonatomic, strong) UIImageView *imageView;

@end

@implementation ImageVC

- (void)viewDidLoad {
    [super viewDidLoad];
    
    self.imageView = [[UIImageView alloc] initWithFrame:CGRectMake(0, 100, kScreenWidth, kScreenWidth)];
    self.imageView.image =[UIImage imageNamed:@"2.png"];
    UIImage *image = [UIImage imageNamed:@"2.png"];
    GPUImageBeautifyFilter *filter = [[GPUImageBeautifyFilter alloc] init];
    UIImage *resultImg = [filter imageByFilteringImage:image];
    self.imageView.image = resultImg;
    [self.view addSubview:self.imageView];
    
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
