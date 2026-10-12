#import <Foundation/Foundation.h>

@interface RecoveryManager : NSObject

+ (instancetype)shared;
- (NSString *)safetySummary;

@end
