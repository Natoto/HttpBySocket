//
//  ViewController.m
//  HttpBySocket
//
//  Created by boob on 2017/6/15.
//  Copyright © 2017年 YY.COM. All rights reserved.
//

#import "ViewController.h"
#import "DCSocketManager.h"
@interface ViewController ()
{
    DCSocketManager *manager;
}
@property (weak, nonatomic) IBOutlet UITextView *lblmsg;
@end

@implementation ViewController

- (void)viewDidLoad {
    [super viewDidLoad];
  
//    [self actionTap:nil];
    
}


- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}
- (IBAction)actionTap:(id)sender {

//@{@"userId":@"65",@"pageNo":@1,@"pageSize":@20}
    manager = [[DCSocketManager alloc] init];
    manager.serverPort = 9010;
    manager.serverHost = @"106.14.83.31";
    [manager getRequestUriName:@"json/friend/get_friend_ship_list?pageNo=1&pageSize=10&userId=65" Param:nil Complete:^(NSDictionary *response) {
        NSLog(@"%@",response);
        self.lblmsg.text = response.description;
    }];


}

- (IBAction)postActionTap:(id)sender {
   
     manager = [[DCSocketManager alloc] init];
    manager.serverPort = 9010;
    manager.serverHost = @"106.14.83.31";
    NSDictionary * param = @{
                             @"channel" : @0,
                             @"device": @"EB84106B449C4F3891740729FF7C45B7",
                             @"opusId": @1384,
                             @"platform": @1,
                             @"praiseType" : @1,
                             @"times" :@1497513220055,
                             @"token": @"22405E4C4E69C0E186CBD2FA23FD1AD7",
                             @"userId": @125,
                             @"version":@"1.0.9",
    };
    
//    json/praise/modify_praise_ship?opusId=1&praiseType=1&token=22405E4C4E69C0E186CBD2FA23FD1AD7&userId=125&platform=1&channel=0&device=EB84106B449C4F3891740729FF7C45B7
    [manager postRequestUriName:@"json/praise/modify_praise_ship" Param:param Complete:^(NSDictionary *response) {
        NSLog(@"%@",response);       self.lblmsg.text = response.description;
    }];

}

@end
