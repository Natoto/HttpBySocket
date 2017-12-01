//
//  AFNViewController.m
//  HttpBySocket
//
//  Created by boob on 2017/6/29.
//  Copyright © 2017年 YY.COM. All rights reserved.
//

#import "AFNViewController.h"
#import <AFNetworking/AFNetworking.h>
#import "HiidoHelper.h"

@interface AFNViewController ()

@end

@implementation AFNViewController


- (IBAction)afnpost:(id)sender {
    
    HiidoParamObject * obj = [HiidoHelper getSmdecryptString:[self timeeventbody]];
    NSString * urlstr = [HiidoHelper getrequeststr:@"http://14.17.109.14/c.gif" param:obj];
    
    NSURL *URL = [NSURL URLWithString:urlstr];
    
    //[NSURL URLWithString:@"http://14.17.109.14/c.gif?act=mbsdkdata&smkdata=000000046bda30c431d588e258c50405e1b41000&EC=0&appkey=6ffb6db7c211b966b735f07c16176f7f&enc=b64&item=mbsdkevent"];
    
    AFHTTPSessionManager *manager = [AFHTTPSessionManager manager];
//    [manager.responseSerializer.acceptableContentTypes setByAddingObject:@"text/html"];
    
    manager.responseSerializer.acceptableContentTypes = [NSSet setWithObjects:@"application/json", @"text/json", @"text/javascript", @"text/plain",@"image/gif", nil];
    
     AFHTTPRequestSerializer * serializer = [AFHTTPRequestSerializer serializer];
    [serializer setValue:@"text/html" forHTTPHeaderField:@"Accept"];
    
    NSString * exbody = obj.base64ReqBody;
    
    manager.requestSerializer = serializer;
    manager.responseSerializer = [AFHTTPResponseSerializer serializer];
 
    [manager POST:URL.absoluteString parameters:nil constructingBodyWithBlock:^(id<AFMultipartFormData>  _Nonnull formData) {
    
        [formData appendPartWithHeaders:nil body:[exbody dataUsingEncoding:NSUTF8StringEncoding]];
        
    } progress:^(NSProgress * _Nonnull uploadProgress) {
        
    } success:^(NSURLSessionDataTask * _Nonnull task, id  _Nullable responseObject) {
             NSLog(@"JSON: %@", responseObject);
    } failure:^(NSURLSessionDataTask * _Nullable task, NSError * _Nonnull error) {
        
        NSLog(@"Error: %@", error);
    }];
  
    
}


-(NSString *)timeeventbody{

    return @"act=mbsdkevent&hdid=e097eaa18a950e241206a609a7983c738f5d16b7&opid=e097eaa18a950e241206a609a7983c738f5d16b7&mac=e097eaa18a950e241206a609a7983c738f5d16b7&idfa=5E1A5D3E-4325-456C-8675-62F5B6940BB4&net=3&from=fromMyDemo&time=1498725561&key=32678678ca2c5d4c1dd70675bc39a4c5&sys=0&app=com.juhui.sdkdemo&imei=e097eaa18a950e241206a609a7983c738f5d16b7&ver=1.32&sdkver=3.1.91&appkey=6ffb6db7c211b966b735f07c16176f7f&guid=A09E2B01-F63B-42C5-9CCD-D6CF9148DD49&sessionid=b800afc599d12aebf5c7ccf73d563238&idfv=13B57757-665C-49EA-A453-3EA00D001FDE&uid=123456&event=0202%3A1%3A1%3A0001%3A";
    
}

-(NSString *)timeeventurl{
    return @"http://14.17.109.14/c.gif?act=mbsdkdata&smkdata=000000046bda30c431d588e258c50405e1b41000&EC=0&appkey=6ffb6db7c211b966b735f07c16176f7f&enc=b64&item=mbsdkevent";
}

-(NSString *)feedbackurl{
    return @"http://14.17.109.14/c.gif?act=mbsdkdata&smkdata=0000000439879ece85bb67f616a3bbf14bef1fca&EC=0&appkey=6ffb6db7c211b966b735f07c16176f7f&enc=b64&item=mbsdkf";
}

-(NSString *)feedbackbody{
    return @"000006015Xmok6emA+cA/UOIWNxnxN8BcpTkU/jmiABkGOYl8AWgx64u+DocbeIu7mogedJ/JCS+DyoNUTyUH1EAOGjTrK3kv/ijPH+chuCUID+9V8Q6NCcqXZ33Hf1fL/TLUJTi1DOZX3mdWj4gG9ZSV/XsQ/oDRzwgZlcARA7yEecUpw3bQye9nfYWZRBYHlJKzst6vSbna+54jaF/3g/R9nR3PpP+iP2JPwg4WidzEY8kGlTryRxO13aue/ZGgw7lfPxn7yN6/a0IOMrJPaS7uAyPhgjhQbJRtbHv1gLBzzrN+4GjifOWFuVmm58JRUpsxQb1SxHiSDOv1pUOnulNVj3GARpPmppvjrtaFwQBGgqm/J0TLUl+Dj0ppDfpJMsm0k11rMAOaL4zyI6w+uXq8PC81FU8A1u2sKlTs3BaRxQXecv26q4yJ1R57FB8Z7HFBSwKi3mtXrKK6mpJATQWSKuRZ+ZUA3C6TJKULmOa4IM3NUr5ynofJvjUrGKkEo4qGL/5s3zAD5zYBeJBZxy9/DbvB/1sDJsQjh8tlteEjUpsVq0nm8TPl68NW+i7G7g4oxFeUleHcPBnMh1njojhZNgbSH6fyasAQhwEp/GQwEzTH77z/TfhALBQ2znt+NKvCGCFa0Nq1AF6ASG0mtKzzL2PqXQ47KDAtjaIRi7cabpiubAIU0uNecMO6gl5LmsBiiIKfagg05mtcpgcH4ttudnHIcvwSW5VaAqIsZ9jO6khFMi+4h/+FHksvpPEQwI/eypJudpBzhLjXzu4hYjkbp03wVi061HwvOLNRyUVHcEztJ8=";
}


- (void)viewDidLoad {
    [super viewDidLoad];
    // Do any additional setup after loading the view.
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
