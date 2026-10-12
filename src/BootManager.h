#import <Foundation/Foundation.h>

@interface BootManager : NSObject

+ (instancetype)shared;
- (NSString *)statusSummary;
- (BOOL)isBootEngineAvailable;

@end
