//
//  NViewController.m
//  NHBottomLoadingView
//
//  Created by Naithar on 05/06/2015.
//  Copyright (c) 2014 Naithar. All rights reserved.
//

#import "NViewController.h"
#import <NHBottomLoadingView.h>

@interface NViewController ()<UITableViewDelegate, UITableViewDataSource>
@property (strong, nonatomic) IBOutlet UITableView *tableView;

@property (nonatomic, strong) NHBottomLoadingView *bottomView;
@end

@implementation NViewController

- (void)viewDidLoad
{
    [super viewDidLoad];
	// Do any additional setup after loading the view, typically from a nib.

    self.tableView.delegate = self;
    self.tableView.dataSource = self;


    __weak __typeof(self) weakSelf = self;

    self.bottomView = [[NHBottomLoadingView alloc] initWithScrollView:self.tableView];
    self.bottomView.refreshBlock = ^{
        dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(5 * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
            [weakSelf.bottomView stopRefreshing];
        [weakSelf.bottomView setState:NHBottomLoadingViewStateFailed];
//            [weakSelf.bottomView setViewWithKey:@"view"];
        });

    };

    UIView *view = [[UIView alloc] initWithFrame:CGRectMake(0, 0, 0, 70)];
    view.backgroundColor = [UIColor redColor];

    [self.bottomView setView:view withHeight:150 forKey:@"view"];

    self.tableView.backgroundColor = [UIColor lightGrayColor];
}

- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
    return 15;
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
    return [[UITableViewCell alloc] initWithStyle:UITableViewCellStyleDefault reuseIdentifier:@""];


}
@end
