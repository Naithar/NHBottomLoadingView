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

    self.bottomView = [[NHBottomLoadingView alloc] initWithScrollView:self.tableView];
//    self
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

    [self.bottomView setState:NHBottomLoadingViewStateFailed];
    return [[UITableViewCell alloc] initWithStyle:UITableViewCellStyleDefault reuseIdentifier:@""];


}
@end
