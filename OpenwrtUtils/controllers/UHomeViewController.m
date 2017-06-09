//
//  UHomeViewController.m
//  OpenwrtUtils
//
//  Created by lujingyu on 2017/3/17.
//  Copyright © 2017年 陈鼎星. All rights reserved.
//

#import "UHomeViewController.h"
#import "USearchWiFiViewController.h"
#import "UBoxViewController.h"
#import "URouterConfig.h"

#define IMAGE_INTERNET [UIImage imageNamed:@"internet"]
#define IMAGE_ROUTER [UIImage imageNamed:@"access_point"]
#define IMAGE_SEARCH [UIImage imageNamed:@"search_wifi"]
#define IMAGE_BOX [UIImage imageNamed:@"openwrtbox"]

/**
 逻辑
 1. 通过ubus.check检测当前是否连在盒子上
 2. 如果没有连在盒子上，可以点击internet继续check
 3. 如果有连在盒子上，则把盒子显示出来
 4. 点击盒子，输入密码，可以登录，登录成功后，搜索WiFi的图标会显示出来
 5. 密码需要缓存下来，下次连上盒子会直接登录，走步骤4流程
 6. 点击WiFi图标，跳转到WiFi搜索列表，在列表中连接成功后，WiFi图标改成路由器图标
 */

@interface UHomeViewController ()
@property (nonatomic, strong) UIButton *internetButton;
@property (nonatomic, strong) UIButton *wifiButton;
@property (nonatomic, strong) UIButton *boxButton;
@end

@implementation UHomeViewController

- (void)dealloc {
}

- (void)viewDidLoad {
    [super viewDidLoad];
    // Do any additional setup after loading the view.
    self.navigationItem.title = @"Openwrt实用工具";
    NSLog(@"CheckUBus started...");

    [self.view addSubview:self.internetButton];
    [self.view addSubview:self.wifiButton];
    [self.view addSubview:self.boxButton];

    [self.internetButton mas_makeConstraints:^(MASConstraintMaker *make) {
      make.centerX.mas_equalTo(self.view.mas_centerX);
      make.top.mas_equalTo(80);
      make.width.mas_equalTo(100);
      make.height.mas_equalTo(100);
    }];

    [self.wifiButton mas_makeConstraints:^(MASConstraintMaker *make) {
      make.centerX.mas_equalTo(self.internetButton.mas_centerX);
      make.top.mas_equalTo(self.internetButton.mas_bottom).offset(40);
      make.width.mas_equalTo(100);
      make.height.mas_equalTo(100);
    }];

    [self.boxButton mas_makeConstraints:^(MASConstraintMaker *make) {
      make.centerX.mas_equalTo(self.internetButton.mas_centerX);
      make.top.mas_equalTo(self.wifiButton.mas_bottom).offset(40);
      make.width.mas_equalTo(100);
      make.height.mas_equalTo(100);
    }];

    self.wifiButton.hidden = YES;
    self.boxButton.hidden = YES;

    [[RACSignal combineLatest:@[ RACObserve([URouterConfig sharedInstance], isBoxAvailable) ]
                       reduce:^(NSNumber *isBoxAvailable) {
                         return @(isBoxAvailable.boolValue);
                       }] subscribeNext:^(NSNumber *rst) {
      if (rst.boolValue) {
          self.boxButton.hidden = NO;
      } else {
          self.boxButton.hidden = YES;
      }
    }];

    [[RACSignal combineLatest:@[ RACObserve([URouterConfig sharedInstance], isBoxLoggedin) ]
                       reduce:^(NSNumber *isBoxLoggedin) {
                         return @(isBoxLoggedin.boolValue);
                       }] subscribeNext:^(NSNumber *rst) {
      if (rst.boolValue) {
          self.wifiButton.hidden = NO;
          [[URouterConfig sharedInstance] getRouterInfo];
      } else {
          self.wifiButton.hidden = YES;
      }
    }];

    [[RACSignal combineLatest:@[ RACObserve([URouterConfig sharedInstance], isWiFiConnected) ]
                       reduce:^(NSNumber *isWiFiConnected) {
                         return @(isWiFiConnected.boolValue);
                       }] subscribeNext:^(NSNumber *rst) {
      if (rst.boolValue) {
          [self.wifiButton setBackgroundImage:IMAGE_ROUTER forState:UIControlStateNormal];
      } else {
          [self.wifiButton setBackgroundImage:IMAGE_SEARCH forState:UIControlStateNormal];
      }
    }];

    //启动时自动检测盒子是否存在
    [[URouterConfig sharedInstance] checkBoxAvailable:^(BOOL available){

    }];

    //启动时自动用之前存储的密码来尝试登陆路由器
    NSString *plistPath = [[NSBundle mainBundle] pathForResource:@"Config" ofType:@"plist"];
    NSMutableDictionary *data = [[NSMutableDictionary alloc] initWithContentsOfFile:plistPath];
    NSString *rootPassword = [data objectForKey:@"rootPassword"];

    [[URouterConfig sharedInstance] loginWithPassword:rootPassword
                                               result:^(BOOL success){
                                               }];
}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

#pragma mark - getters

- (UIButton *)internetButton {
    if (!_internetButton) {
        _internetButton = [[UIButton alloc] init];
        [_internetButton setBackgroundImage:IMAGE_INTERNET forState:UIControlStateNormal];
        [_internetButton addTarget:self action:@selector(actionInternet:) forControlEvents:UIControlEventTouchUpInside];
    }
    return _internetButton;
}

- (UIButton *)wifiButton {
    if (!_wifiButton) {
        _wifiButton = [[UIButton alloc] init];
        [_wifiButton setBackgroundImage:IMAGE_SEARCH forState:UIControlStateNormal];
        [_wifiButton addTarget:self action:@selector(actionWiFi:) forControlEvents:UIControlEventTouchUpInside];
    }
    return _wifiButton;
}

- (UIButton *)boxButton {
    if (!_boxButton) {
        _boxButton = [[UIButton alloc] init];
        [_boxButton setBackgroundImage:IMAGE_BOX forState:UIControlStateNormal];
        [_boxButton addTarget:self action:@selector(actionBox:) forControlEvents:UIControlEventTouchUpInside];
    }
    return _boxButton;
}

- (void)toast:(NSString *)message {
    [[[UIAlertView alloc] initWithTitle:@"提示" message:message delegate:nil cancelButtonTitle:@"ok" otherButtonTitles:nil] show];
}

#pragma mark - actions

- (void)actionInternet:(id)sender {
    if ([[URouterConfig sharedInstance] isBoxLoggedin]) {
            [self hideLoading];
            NSString *message = [[[[[URouterConfig sharedInstance] wanStatus] objectForKey:@"ipv4-address"] objectAtIndex:0] objectForKey:@"address"];
            [self toast:message];
    }
}

- (void)actionWiFi:(id)sender {
    USearchWiFiViewController *vc = [[USearchWiFiViewController alloc] init];
    [self.navigationController pushViewController:vc animated:YES];
}

- (void)actionBox:(id)sender {
    if ([[URouterConfig sharedInstance] isBoxLoggedin]) {
        UBoxViewController *vc = [[UBoxViewController alloc] init];
        [self.navigationController pushViewController:vc animated:YES];
    } else {
        UIAlertView *alert = [[UIAlertView alloc] initWithTitle:@"请输入密码" message:nil delegate:self cancelButtonTitle:@"cancel" otherButtonTitles:@"done", nil];
        alert.alertViewStyle = UIAlertViewStylePlainTextInput;
        [alert show];
    }
}

- (void)alertView:(UIAlertView *)alertView clickedButtonAtIndex:(NSInteger)buttonIndex {
    if (buttonIndex == alertView.firstOtherButtonIndex) {
        UITextField *pwdField = [alertView textFieldAtIndex:0];
        [self showLoading];
        [[URouterConfig sharedInstance] loginWithPassword:pwdField.text
                                                   result:^(BOOL success) {
                                                     [self hideLoading];
                                                   }];
    }
}

@end
