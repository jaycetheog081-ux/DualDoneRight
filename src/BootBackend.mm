#import "BootBackend.h"

static NSString * const DDDRBootErrorDomain =
    @"com.dualdoneright.boot";

@implementation BootBackend

+ (instancetype)shared {
    static BootBackend *instance;
    static dispatch_once_t onceToken;

    dispatch_once(&onceToken, ^{
        instance = [[BootBackend alloc] init];
    });

    return instance;
}

- (BOOL)isAvailableForDevice:(NSString *)deviceIdentifier
              iosMajorVersion:(NSInteger)version {
    /*
     A real backend must be explicitly implemented and verified for
     the exact hardware and firmware.

     No compatible on-device A7/iOS 12.5.8 backend has been integrated.
     Do not return YES based on device architecture alone.
    */
    return NO;
}

- (NSString *)availabilitySummaryForDevice:(NSString *)deviceIdentifier
                            iosMajorVersion:(NSInteger)version {
    if ([self isAvailableForDevice:deviceIdentifier
                   iosMajorVersion:version]) {
        return @"A compatible boot backend is available.";
    }

    return [NSString stringWithFormat:
        @"No verified boot backend is configured for %@ with secondary "
         "iOS %ld.\n\n"
         "Booting is disabled. This prevents the app from claiming that "
         "a secondary OS can boot when no compatible implementation exists.",
         deviceIdentifier ?: @"this device",
         (long)version];
}

- (BOOL)bootSecondarySystemWithError:(NSError **)error {
    if (error) {
        *error = [NSError errorWithDomain:DDDRBootErrorDomain
                                     code:1
                                 userInfo:@{
            NSLocalizedDescriptionKey:
                @"Booting is unavailable: no verified backend has been integrated."
        }];
    }

    return NO;
}

@end
