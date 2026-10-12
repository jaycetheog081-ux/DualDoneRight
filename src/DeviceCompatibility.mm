#import "DeviceCompatibility.h"
#import <UIKit/UIKit.h>
#import <sys/utsname.h>

@implementation DeviceCompatibility

+ (instancetype)shared {
    static DeviceCompatibility *instance;
    static dispatch_once_t onceToken;

    dispatch_once(&onceToken, ^{
        instance = [[DeviceCompatibility alloc] init];
    });

    return instance;
}

- (NSString *)deviceModel {
    struct utsname systemInfo;
    uname(&systemInfo);

    return [NSString stringWithUTF8String:systemInfo.machine]
        ?: @"Unknown device";
}

- (NSString *)systemVersion {
    return [[UIDevice currentDevice] systemVersion]
        ?: @"Unknown iOS version";
}

- (BOOL)is64BitDevice {
#if defined(__LP64__)
    return YES;
#else
    return NO;
#endif
}

- (NSString *)summary {
    NSString *model = [self deviceModel];
    NSString *version = [self systemVersion];
    NSString *architecture =
        [self is64BitDevice] ? @"64-bit" : @"32-bit";

    return [NSString stringWithFormat:
        @"DEVICE INFORMATION\n\nModel: %@\niOS: %@\nArchitecture: %@\n\n"
         "Note: Architecture alone does not confirm dual-boot compatibility.",
         model, version, architecture];
}

@end
