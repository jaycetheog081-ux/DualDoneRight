#import "BootManager.h"

@implementation BootManager

+ (instancetype)shared {
    static BootManager *instance;
    static dispatch_once_t onceToken;

    dispatch_once(&onceToken, ^{
        instance = [[BootManager alloc] init];
    });

    return instance;
}

- (BOOL)isBootEngineAvailable {
    return NO;
}

- (NSString *)statusSummary {
    return
        @"DUAL-BOOT STATUS\n\n"
         "Boot engine: Not implemented\n"
         "Secondary OS: Not configured\n"
         "Boot configuration: Unchanged\n\n"
         "The current build is a management prototype. "
         "It cannot create a secondary iOS installation or boot it yet.\n\n"
         "A working engine requires a verified boot method for the "
         "specific device and firmware.";
}

@end
