#import <ifaddrs.h>
#import <arpa/inet.h>
#import <objc/runtime.h>

@interface SBWiFiManager : NSObject
+ (id)sharedInstance;
- (BOOL)wiFiEnabled;
@end

@interface UIStatusBarDataNetworkItemView : UIView
- (NSString *)getIPAddress;
- (void)fadeInView:(UIView *)view;
- (void)fadeOutView:(UIView *)view;
@end

%hook UIStatusBarDataNetworkItemView

- (void)setUserInteractionEnabled:(BOOL)set
{
    %orig(YES);
}

- (void)touchesBegan:(NSSet *)touches withEvent:(UIEvent *)event
{
    if (![[objc_getClass("SBWiFiManager") sharedInstance] wiFiEnabled]) {
        return;
    }

    UIView *backgroundView = [[UIView alloc] initWithFrame:self.superview.bounds];
    backgroundView.backgroundColor = [UIColor clearColor];
    backgroundView.alpha = 0.f;

    UILabel *ipLabel = [[UILabel alloc] initWithFrame:backgroundView.bounds];
    ipLabel.backgroundColor = [UIColor clearColor];
    ipLabel.font = [UIFont boldSystemFontOfSize:13];
    ipLabel.textColor = [UIColor whiteColor];
    ipLabel.textAlignment = NSTextAlignmentCenter;
    ipLabel.text = [self getIPAddress];

    [backgroundView addSubview:ipLabel];
    [self.superview addSubview:backgroundView];

    [self fadeInView:backgroundView];
    dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(2 * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
        [self fadeOutView:backgroundView];
    });
}

%new
- (void)fadeInView:(UIView *)view
{
    [UIView animateWithDuration:0.2 animations:^{
        for (UIView *item in self.superview.subviews) {
            if (item != view) {
                item.alpha = 0.f;
            }
        }
    } completion:^(BOOL finished) {
        [UIView animateWithDuration:0.2 animations:^{
            view.alpha = 1.f;
        }];
    }];
}

%new
- (void)fadeOutView:(UIView *)view
{
    [UIView animateWithDuration:0.2 animations:^{
        view.alpha = 0.f;
    } completion:^(BOOL finished) {
        [view removeFromSuperview];
        [UIView animateWithDuration:0.2 animations:^{
            for (UIView *item in self.superview.subviews) {
                if (item != view) {
                    item.alpha = 1.f;
                }
            }
        }];
    }];
}

%new
- (NSString *)getIPAddress
{
    NSString *address = @"error";
    struct ifaddrs *interfaces = NULL;
    struct ifaddrs *temp_addr = NULL;
    // retrieve the current interfaces - returns 0 on success
    if (getifaddrs(&interfaces) == 0) {
        // Loop through linked list of interfaces
        temp_addr = interfaces;
        while(temp_addr != NULL) {
            if(temp_addr->ifa_addr->sa_family == AF_INET) {
                // Check if interface is en0 which is the wifi connection on the iPhone
                if([[NSString stringWithUTF8String:temp_addr->ifa_name] isEqualToString:@"en0"]) {
                    // Get NSString from C String
                    address = [NSString stringWithUTF8String:inet_ntoa(((struct sockaddr_in *)temp_addr->ifa_addr)->sin_addr)];
                }
            }
            temp_addr = temp_addr->ifa_next;
        }
    }
    // Free memory
    freeifaddrs(interfaces);
    return address;
}

%end
