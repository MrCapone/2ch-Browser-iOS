//
//  DVBCaptchaManager.m
//  dvach-browser
//
//  Created by Andrey Konstantinov on 09/02/16.
//  Copyright © 2016 8of. All rights reserved.
//

#import "DVBConstants.h"
#import "DVBCaptchaManager.h"
#import "dvach_browser-Swift.h"

@interface DVBCaptchaManager ()

@property (nonatomic, strong) DVBNetworking *networkManager;

@end

@implementation DVBCaptchaManager

- (instancetype)init
{
    self = [super init];

    if (self) {
        _networkManager = [[DVBNetworking alloc] init];
    }

    return self;
}

- (void)getCaptchaImageUrl:(NSString *)threadNum andCompletion:(void (^)(NSString *, NSString *))completion
{
    [_networkManager getCaptchaImageUrl:threadNum
                          andCompletion:^( NSString * _Nullable fullUrl, NSString * _Nullable captchaId)
    {
        if (fullUrl) {
            completion(fullUrl, captchaId);
        } else {
            completion(nil, nil);
        }

    }];
}

@end
