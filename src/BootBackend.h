#import <Foundation/Foundation.h>

@interface BootBackend : NSObject

+ (instancetype)shared;

- (BOOL)isAvailableForDevice:(NSString *)deviceIdentifier
              iosMajorVersion:(NSInteger)version;

- (NSString *)availabilitySummaryForDevice:(NSString *)deviceIdentifier
                            iosMajorVersion:(NSInteger)version;

- (BOOL)bootSecondarySystemWithError:(NSError **)error;

@end
