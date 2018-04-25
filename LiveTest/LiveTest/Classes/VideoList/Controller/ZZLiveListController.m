//
//  ZZLiveListController.m
//  LiveTest
//
//  Created by 志方 on 17/3/23.
//  Copyright © 2017年 志方. All rights reserved.
//

#import "ZZLiveListController.h"
#import <AFNetworking.h>
#import <MJExtension.h>
#import "ZZLiveModel.h"
#import "ZZLiveCell.h"
#import "ZZLiveController.h"
#import "ZZCaptureController.h"
#import "ImageVC.h"

static NSString * const ID = @"cell";
@interface ZZLiveListController ()

@property(nonatomic,strong) NSMutableArray *liveArray;

@end

@implementation ZZLiveListController

- (void)viewDidLoad {
    [super viewDidLoad];
    self.view.backgroundColor = [UIColor whiteColor];
    self.title = @"直播列表";
    
    [self loadData];
    
    [self.tableView registerNib:[UINib nibWithNibName:@"ZZLiveCell" bundle:nil] forCellReuseIdentifier:ID];
    self.tableView.separatorStyle = UITableViewCellSeparatorStyleNone;
    
    UIBarButtonItem *capture = [[UIBarButtonItem alloc] initWithTitle:@"直播" style:UIBarButtonItemStyleDone target:self action:@selector(captureAction)];
    
    self.navigationItem.rightBarButtonItem = capture;
    
    
}
-(void) captureAction {
    [self.navigationController pushViewController:[[ZZCaptureController alloc] init] animated:YES];
//    [self.navigationController pushViewController:[ImageVC new] animated:YES];
}
-(void)viewWillAppear:(BOOL)animated{
    [super viewWillAppear:animated];
    [self.navigationController.navigationBar setHidden:NO];
}
-(void) loadData {
    //请求映客数据
    NSString *urlStr = @"http://116.211.167.106/api/live/aggregation?uid=133825214&interest=1";
    
    AFHTTPSessionManager *manager = [AFHTTPSessionManager manager];
    manager.responseSerializer = [AFJSONResponseSerializer serializer];
    manager.responseSerializer.acceptableContentTypes = [NSSet setWithObjects:@"text/plain", nil];
    [manager GET:urlStr parameters:nil success:^(NSURLSessionDataTask * _Nonnull task, id  _Nullable responseObject) {
        _liveArray = [ZZLiveModel mj_objectArrayWithKeyValuesArray:responseObject[@"lives"]];
        [self.tableView reloadData];
    } failure:^(NSURLSessionDataTask * _Nullable task, NSError * _Nonnull error) {
        NSLog(@"%@",error);
    }];
}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

#pragma mark - Table view data source

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView {
    return 1;
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
    return _liveArray.count;
}


- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
    ZZLiveCell *cell = [tableView dequeueReusableCellWithIdentifier:ID];
    
    cell.live = _liveArray[indexPath.row];
    
    return cell;
}

-(CGFloat)tableView:(UITableView *)tableView heightForRowAtIndexPath:(NSIndexPath *)indexPath{
    return 430;
}

-(void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath{
    [tableView deselectRowAtIndexPath:indexPath animated:YES];
    ZZLiveController *liveVC = [[ZZLiveController alloc] init];
    liveVC.live = _liveArray[indexPath.row];
    
    [self.navigationController pushViewController:liveVC animated:YES];
}

@end
