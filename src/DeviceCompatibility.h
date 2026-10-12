#import <Foundation/Foundation.h>

@interface DeviceCompatibility : NSObject

+ (instancetype)shared;
- (NSString *)summary;
- (NSString *)deviceModel;
- (NSString *)systemVersion;
- (BOOL)is64BitDevice;

@end
