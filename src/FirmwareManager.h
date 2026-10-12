#import <Foundation/Foundation.h>

@interface FirmwareManager : NSObject

+ (instancetype)shared;
- (NSString *)requirementsSummary;

@end
