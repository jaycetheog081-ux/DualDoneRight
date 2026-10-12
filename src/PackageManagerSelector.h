#import <Foundation/Foundation.h>

typedef NS_ENUM(NSInteger, DDDRPackageManager) {
    DDDRPackageManagerUnknown = 0,
    DDDRPackageManagerCydia,
    DDDRPackageManagerZebra
};

@interface PackageManagerSelector : NSObject

+ (instancetype)shared;

- (DDDRPackageManager)managerForIOSMajorVersion:(NSInteger)version;
- (NSString *)nameForIOSMajorVersion:(NSInteger)version;
- (NSString *)compatibilitySummaryForIOSMajorVersion:(NSInteger)version;

@end
