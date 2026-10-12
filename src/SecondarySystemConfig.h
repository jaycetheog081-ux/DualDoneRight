#import <Foundation/Foundation.h>

@interface SecondarySystemConfig : NSObject

@property (nonatomic, assign) NSInteger iosMajorVersion;
@property (nonatomic, copy) NSString *deviceIdentifier;
@property (nonatomic, copy) NSString *systemRootPath;
@property (nonatomic, copy) NSString *packageManagerName;

+ (instancetype)shared;

- (BOOL)configureForIOSMajorVersion:(NSInteger)version
                   deviceIdentifier:(NSString *)device
                      systemRootPath:(NSString *)rootPath
                              error:(NSError **)error;

- (NSDictionary *)dictionaryRepresentation;
- (BOOL)saveToURL:(NSURL *)url error:(NSError **)error;
- (BOOL)loadFromURL:(NSURL *)url error:(NSError **)error;
- (void)reset;

@end
