#import <Foundation/Foundation.h>

@interface SecondarySystemInstaller : NSObject

+ (instancetype)shared;

- (BOOL)validateSecondaryRootPath:(NSString *)rootPath
                            error:(NSError **)error;

- (BOOL)configureSecondarySystemAtRootPath:(NSString *)rootPath
                          iosMajorVersion:(NSInteger)version
                          deviceIdentifier:(NSString *)deviceIdentifier
                                     error:(NSError **)error;

- (NSString *)installationSummary;

@end
