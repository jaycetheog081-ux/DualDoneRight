#import "PackageManagerSelector.h"

@implementation PackageManagerSelector

+ (instancetype)shared {
    static PackageManagerSelector *instance;
    static dispatch_once_t onceToken;

    dispatch_once(&onceToken, ^{
        instance = [[PackageManagerSelector alloc] init];
    });

    return instance;
}

- (DDDRPackageManager)managerForIOSMajorVersion:(NSInteger)version {
    if (version >= 1 && version <= 8) {
        return DDDRPackageManagerCydia;
    }

    if (version >= 9 && version <= 12) {
        return DDDRPackageManagerZebra;
    }

    return DDDRPackageManagerUnknown;
}

- (NSString *)nameForIOSMajorVersion:(NSInteger)version {
    switch ([self managerForIOSMajorVersion:version]) {
        case DDDRPackageManagerCydia:
            return @"Cydia";

        case DDDRPackageManagerZebra:
            return @"Zebra";

        default:
            return @"Unsupported / not configured";
    }
}

- (NSString *)compatibilitySummaryForIOSMajorVersion:(NSInteger)version {
    NSString *name = [self nameForIOSMajorVersion:version];

    if ([name isEqualToString:@"Unsupported / not configured"]) {
        return [NSString stringWithFormat:
            @"No package manager is configured for iOS %ld.",
            (long)version];
    }

    return [NSString stringWithFormat:
        @"Selected package manager: %@\n\n"
         "This is the requested version policy, not a guarantee that "
         "a compatible package and jailbreak bootstrap are available "
         "for the target installation.",
        name];
}

@end
