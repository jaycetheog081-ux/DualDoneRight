#import "FirmwareManager.h"
#import <UIKit/UIKit.h>

@implementation FirmwareManager

+ (instancetype)shared {
    static FirmwareManager *instance;
    static dispatch_once_t onceToken;

    dispatch_once(&onceToken, ^{
        instance = [[FirmwareManager alloc] init];
    });

    return instance;
}

- (NSString *)requirementsSummary {
    NSString *version = [[UIDevice currentDevice] systemVersion];

    return [NSString stringWithFormat:
        @"FIRMWARE CHECK\n\n"
         "Current iOS: %@\n\n"
         "Before attempting dual-boot, compatibility must be verified for:\n\n"
         "• Exact device model and chip\n"
         "• Current firmware build\n"
         "• Bootrom and boot-chain capabilities\n"
         "• Available secondary firmware image\n"
         "• Required bootloader and jailbreak environment\n\n"
         "A rootful jailbreak does not automatically make a device "
         "capable of booting another iOS installation.\n\n"
         "No firmware changes are performed by this prototype.",
         version];
}

@end
