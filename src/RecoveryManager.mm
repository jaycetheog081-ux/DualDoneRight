#import "RecoveryManager.h"

@implementation RecoveryManager

+ (instancetype)shared {
    static RecoveryManager *instance;
    static dispatch_once_t onceToken;

    dispatch_once(&onceToken, ^{
        instance = [[RecoveryManager alloc] init];
    });

    return instance;
}

- (NSString *)safetySummary {
    return
        @"RECOVERY & SAFETY\n\n"
         "Current protection status:\n\n"
         "• No partitions are modified.\n"
         "• No boot arguments are changed.\n"
         "• No firmware is flashed.\n"
         "• No reboot-to-secondary-OS operation is available.\n\n"
         "Before testing a future boot engine, make a backup and verify "
         "that you have a recovery method for your exact device.\n\n"
         "Never assume that a jailbreak recovery method can recover "
         "a failed secondary-OS boot.";
}

@end
