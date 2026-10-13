#import "IPSWManager.h"

#import <UIKit/UIKit.h>
#import <CommonCrypto/CommonDigest.h>
#import <sys/utsname.h>
#import <sys/statvfs.h>

static NSString * const kTargetDevice = @"iPad4,4";
static NSString * const kTargetVersion = @"8.4.1";
static NSString * const kTargetBuild = @"12H321";

static NSString * const kExpectedSHA256 =
@"61b61053148ca50aae015b1bb0625750ac9e687868eb01be3b699ffc2ad845c8";

static NSString * const kFirmwareFilename =
@"iPad4,4_8.4.1_12H321_Restore.ipsw";

static NSString * const kIPSWErrorDomain = @"com.dualdoneright.ipsw";

@interface IPSWManager ()

@property (nonatomic, strong) NSURLSession *session;
@property (nonatomic, strong) NSURLSessionDownloadTask *downloadTask;

@property (nonatomic, copy) void (^progressHandler)(double progress);

@property (nonatomic, copy) void (^completionHandler)(
    NSURL * _Nullable fileURL,
    NSError * _Nullable error
);

@property (nonatomic, assign, readwrite) BOOL isDownloading;

@end

@implementation IPSWManager

+ (instancetype)sharedManager {
    static IPSWManager *manager;
    static dispatch_once_t onceToken;

    dispatch_once(&onceToken, ^{
        manager = [[IPSWManager alloc] init];
    });

    return manager;
}

- (instancetype)init {
    self = [super init];

    if (self) {
        NSURLSessionConfiguration *configuration =
            [NSURLSessionConfiguration defaultSessionConfiguration];

        configuration.timeoutIntervalForRequest = 120.0;
        configuration.timeoutIntervalForResource = 8.0 * 60.0 * 60.0;
        configuration.allowsCellularAccess = YES;

        NSOperationQueue *queue = [[NSOperationQueue alloc] init];
        queue.maxConcurrentOperationCount = 1;

        _session = [NSURLSession sessionWithConfiguration:configuration
                                                 delegate:self
                                            delegateQueue:queue];
    }

    return self;
}

#pragma mark - Device and Storage

- (NSString *)deviceIdentifier {
    struct utsname systemInfo;
    uname(&systemInfo);

    return [NSString stringWithUTF8String:systemInfo.machine];
}

- (NSString *)firmwareDirectoryPath {
    NSArray<NSURL *> *directories =
        [[NSFileManager defaultManager]
            URLsForDirectory:NSDocumentDirectory
                   inDomains:NSUserDomainMask];

    NSURL *documentsURL = directories.firstObject;

    return [[documentsURL URLByAppendingPathComponent:@"Firmware"
                                          isDirectory:YES] path];
}

- (NSError *)errorWithCode:(NSInteger)code
               description:(NSString *)description {
    return [NSError errorWithDomain:kIPSWErrorDomain
                               code:code
                           userInfo:@{
        NSLocalizedDescriptionKey : description
    }];
}

- (BOOL)checkAvailableStorage:(NSError **)error {
    struct statvfs filesystemInfo;

    if (statvfs(NSHomeDirectory().fileSystemRepresentation,
                &filesystemInfo) != 0) {
        if (error) {
            *error = [self errorWithCode:10
                             description:@"Could not determine available storage."];
        }

        return NO;
    }

    unsigned long long availableBytes =
        (unsigned long long)filesystemInfo.f_bavail *
        (unsigned long long)filesystemInfo.f_frsize;

    const unsigned long long requiredBytes =
        3ULL * 1024ULL * 1024ULL * 1024ULL;

    if (availableBytes < requiredBytes) {
        if (error) {
            *error = [self errorWithCode:11
                description:@"At least 3 GB of free storage is required before downloading firmware."];
        }

        return NO;
    }

    return YES;
}

#pragma mark - Download

- (void)downloadIOS841WithProgress:(void (^)(double))progress
                        completion:(void (^)(NSURL *, NSError *))completion {

    if (self.isDownloading) {
        completion(nil, [self errorWithCode:1
                               description:@"A firmware download is already running."]);
        return;
    }

    NSString *device = [self deviceIdentifier];

    if (![device isEqualToString:kTargetDevice]) {
        NSString *message = [NSString stringWithFormat:
            @"This firmware is configured for %@ only. Detected device: %@.",
            kTargetDevice, device];

        completion(nil, [self errorWithCode:2 description:message]);
        return;
    }

    NSError *storageError = nil;

    if (![self checkAvailableStorage:&storageError]) {
        completion(nil, storageError);
        return;
    }

    self.progressHandler = progress;
    self.completionHandler = completion;
    self.isDownloading = YES;

    NSURL *apiURL = [NSURL URLWithString:
        @"https://api.ipsw.me/v4/device/iPad4,4?type=ipsw"];

    NSURLSessionDataTask *metadataTask =
        [self.session dataTaskWithURL:apiURL
                    completionHandler:^(NSData *data,
                                        NSURLResponse *response,
                                        NSError *networkError) {

        if (networkError) {
            [self finishWithURL:nil error:networkError];
            return;
        }

        NSHTTPURLResponse *httpResponse =
            (NSHTTPURLResponse *)response;

        if (httpResponse.statusCode < 200 ||
            httpResponse.statusCode >= 300) {
            [self finishWithURL:nil
                          error:[self errorWithCode:3
                                       description:@"Firmware metadata request failed."]];
            return;
        }

        NSError *jsonError = nil;

        id json = [NSJSONSerialization JSONObjectWithData:data
                                                  options:0
                                                    error:&jsonError];

        if (jsonError || ![json isKindOfClass:[NSDictionary class]]) {
            [self finishWithURL:nil
                          error:[self errorWithCode:4
                                       description:@"Could not parse firmware metadata."]];
            return;
        }

        NSDictionary *metadata = (NSDictionary *)json;
        NSArray *firmwares = metadata[@"firmwares"];

        if (![firmwares isKindOfClass:[NSArray class]]) {
            [self finishWithURL:nil
                          error:[self errorWithCode:5
                                       description:@"Firmware list was missing from the metadata response."]];
            return;
        }

        NSDictionary *match = nil;

        for (id item in firmwares) {
            if (![item isKindOfClass:[NSDictionary class]]) {
                continue;
            }

            NSDictionary *firmware = (NSDictionary *)item;

            NSString *version = firmware[@"version"];
            NSString *build = firmware[@"buildid"];

            if ([version isEqualToString:kTargetVersion] &&
                [build isEqualToString:kTargetBuild]) {
                match = firmware;
                break;
            }
        }

        if (!match) {
            [self finishWithURL:nil
                          error:[self errorWithCode:6
                                       description:@"iOS 8.4.1 build 12H321 was not found in the firmware metadata."]];
            return;
        }

        /*
         The API may provide sha1sum rather than sha256.
         Do not require an API sha256 property here.
         The downloaded file is independently checked using
         the known SHA-256 checksum in validateDownloadedIPSWAtURL:.
         */

        NSString *downloadString = match[@"url"];

        if (![downloadString isKindOfClass:[NSString class]] ||
            downloadString.length == 0) {
            [self finishWithURL:nil
                          error:[self errorWithCode:7
                                       description:@"Firmware metadata did not contain a download URL."]];
            return;
        }

        NSURL *downloadURL = [NSURL URLWithString:downloadString];

        if (!downloadURL ||
            ![downloadURL.scheme.lowercaseString isEqualToString:@"https"]) {
            [self finishWithURL:nil
                          error:[self errorWithCode:8
                                       description:@"The firmware download URL is invalid or does not use HTTPS."]];
            return;
        }

        NSURLSessionDownloadTask *task =
            [self.session downloadTaskWithURL:downloadURL];

        self.downloadTask = task;
        [task resume];
    }];

    [metadataTask resume];
}

#pragma mark - Download Progress

- (void)URLSession:(NSURLSession *)session
      downloadTask:(NSURLSessionDownloadTask *)downloadTask
      didWriteData:(int64_t)bytesWritten
 totalBytesWritten:(int64_t)totalBytesWritten
totalBytesExpectedToWrite:(int64_t)totalBytesExpectedToWrite {

    if (totalBytesExpectedToWrite <= 0) {
        return;
    }

    double fraction =
        (double)totalBytesWritten / (double)totalBytesExpectedToWrite;

    fraction = MAX(0.0, MIN(1.0, fraction));

    void (^handler)(double) = self.progressHandler;

    if (handler) {
        dispatch_async(dispatch_get_main_queue(), ^{
            handler(fraction);
        });
    }
}

#pragma mark - Download Complete

- (void)URLSession:(NSURLSession *)session
      downloadTask:(NSURLSessionDownloadTask *)downloadTask
 didFinishDownloadingToURL:(NSURL *)location {

    NSHTTPURLResponse *response =
        (NSHTTPURLResponse *)downloadTask.response;

    if (response.statusCode < 200 || response.statusCode >= 300) {
        [self finishWithURL:nil
                      error:[self errorWithCode:9
                                   description:@"The firmware server returned an unsuccessful HTTP response."]];
        return;
    }

    NSURL *directoryURL =
        [NSURL fileURLWithPath:[self firmwareDirectoryPath]
                  isDirectory:YES];

    NSError *directoryError = nil;

    [[NSFileManager defaultManager]
        createDirectoryAtURL:directoryURL
 withIntermediateDirectories:YES
                  attributes:nil
                       error:&directoryError];

    if (directoryError) {
        [self finishWithURL:nil error:directoryError];
        return;
    }

    NSURL *destinationURL =
        [directoryURL URLByAppendingPathComponent:kFirmwareFilename];

    NSFileManager *fileManager = [NSFileManager defaultManager];

    [fileManager removeItemAtURL:destinationURL error:nil];

    NSError *moveError = nil;

    if (![fileManager moveItemAtURL:location
                              toURL:destinationURL
                              error:&moveError]) {
        [self finishWithURL:nil error:moveError];
        return;
    }

    [self validateDownloadedIPSWAtURL:destinationURL
                           completion:^(BOOL valid, NSString *message) {

        if (!valid) {
            [fileManager removeItemAtURL:destinationURL error:nil];

            [self finishWithURL:nil
                          error:[self errorWithCode:12
                                       description:message]];
            return;
        }

        [self finishWithURL:destinationURL error:nil];
    }];
}

- (void)URLSession:(NSURLSession *)session
              task:(NSURLSessionTask *)task
didCompleteWithError:(NSError *)error {

    if (error) {
        [self finishWithURL:nil error:error];
    }
}

#pragma mark - SHA-256 Validation

- (void)validateDownloadedIPSWAtURL:(NSURL *)fileURL
                         completion:(void (^)(BOOL, NSString *))completion {

    dispatch_async(dispatch_get_global_queue(QOS_CLASS_UTILITY, 0), ^{

        NSFileHandle *handle =
            [NSFileHandle fileHandleForReadingAtPath:fileURL.path];

        if (!handle) {
            dispatch_async(dispatch_get_main_queue(), ^{
                completion(NO, @"Could not open the downloaded firmware.");
            });

            return;
        }

        CC_SHA256_CTX context;
        CC_SHA256_Init(&context);

        BOOL readError = NO;

        @try {
            while (YES) {
                @autoreleasepool {
                    NSData *chunk =
                        [handle readDataOfLength:1024 * 1024];

                    if (chunk.length == 0) {
                        break;
                    }

                    CC_SHA256_Update(&context,
                                     chunk.bytes,
                                     (CC_LONG)chunk.length);
                }
            }
        } @catch (NSException *exception) {
            readError = YES;
        } @finally {
            [handle closeFile];
        }

        if (readError) {
            dispatch_async(dispatch_get_main_queue(), ^{
                completion(NO,
                    @"An error occurred while reading the firmware file.");
            });

            return;
        }

        unsigned char digest[CC_SHA256_DIGEST_LENGTH];
        CC_SHA256_Final(digest, &context);

        NSMutableString *hexDigest =
            [NSMutableString stringWithCapacity:
                CC_SHA256_DIGEST_LENGTH * 2];

        for (int i = 0; i < CC_SHA256_DIGEST_LENGTH; i++) {
            [hexDigest appendFormat:@"%02x", digest[i]];
        }

        BOOL valid =
            [hexDigest.lowercaseString
                isEqualToString:kExpectedSHA256];

        NSString *message = valid
            ? @"SHA-256 verified. The IPSW matches the expected firmware."
            : [NSString stringWithFormat:
                @"SHA-256 mismatch. Expected %@ but received %@.",
                kExpectedSHA256, hexDigest];

        dispatch_async(dispatch_get_main_queue(), ^{
            completion(valid, message);
        });
    });
}

#pragma mark - Finish

- (void)finishWithURL:(NSURL *)fileURL error:(NSError *)error {
    if (!self.isDownloading) {
        return;
    }

    self.isDownloading = NO;
    self.downloadTask = nil;

    void (^completion)(NSURL *, NSError *) =
        self.completionHandler;

    self.progressHandler = nil;
    self.completionHandler = nil;

    if (completion) {
        dispatch_async(dispatch_get_main_queue(), ^{
            completion(fileURL, error);
        });
    }
}

@end
