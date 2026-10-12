#import <Foundation/Foundation.h>

NS_ASSUME_NONNULL_BEGIN

@interface IPSWManager : NSObject <NSURLSessionDownloadDelegate>

+ (instancetype)sharedManager;

@property (nonatomic, readonly) BOOL isDownloading;

- (void)downloadIOS841WithProgress:(void (^)(double progress))progress
                        completion:(void (^)(NSURL * _Nullable fileURL,
                                             NSError * _Nullable error))completion;

- (void)validateDownloadedIPSWAtURL:(NSURL *)fileURL
                         completion:(void (^)(BOOL valid,
                                              NSString *message))completion;

- (NSString *)firmwareDirectoryPath;

@end

NS_ASSUME_NONNULL_END
