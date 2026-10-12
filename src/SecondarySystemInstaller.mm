#import "SecondarySystemInstaller.h"
#import "SecondarySystemConfig.h"
#import "PackageManagerSelector.h"
#import <sys/stat.h>

static NSString * const DDDRInstallerErrorDomain =
    @"com.dualdoneright.installer";

@implementation SecondarySystemInstaller {
    NSString *_lastSummary;
}

+ (instancetype)shared {
    static SecondarySystemInstaller *instance;
    static dispatch_once_t onceToken;

    dispatch_once(&onceToken, ^{
        instance = [[SecondarySystemInstaller alloc] init];
    });

    return instance;
}

- (instancetype)init {
    self = [super init];

    if (self) {
        _lastSummary =
            @"No secondary system has been configured.\n\n"
             "A firmware installer and compatible boot backend are not included.";
    }

    return self;
}

- (BOOL)validateSecondaryRootPath:(NSString *)rootPath
                            error:(NSError **)error {
    if (rootPath.length == 0 || ![rootPath isAbsolutePath]) {
        if (error) {
            *error = [NSError errorWithDomain:DDDRInstallerErrorDomain
                                         code:1
                                     userInfo:@{
                NSLocalizedDescriptionKey:
                    @"Provide an absolute path to an existing secondary root filesystem."
            }];
        }
        return NO;
    }

    BOOL isDirectory = NO;
    BOOL exists = [[NSFileManager defaultManager]
        fileExistsAtPath:rootPath isDirectory:&isDirectory];

    if (!exists || !isDirectory) {
        if (error) {
            *error = [NSError errorWithDomain:DDDRInstallerErrorDomain
                                         code:2
                                     userInfo:@{
                NSLocalizedDescriptionKey:
                    @"The secondary root path does not exist or is not a directory. "
                     "This module does not create partitions or install firmware."
            }];
        }
        return NO;
    }

    return YES;
}

- (BOOL)configureSecondarySystemAtRootPath:(NSString *)rootPath
                          iosMajorVersion:(NSInteger)version
                          deviceIdentifier:(NSString *)deviceIdentifier
                                     error:(NSError **)error {
    if (![self validateSecondaryRootPath:rootPath error:error]) {
        return NO;
    }

    SecondarySystemConfig *config = [SecondarySystemConfig shared];

    if (![config configureForIOSMajorVersion:version
                            deviceIdentifier:deviceIdentifier
                               systemRootPath:rootPath
                                       error:error]) {
        return NO;
    }

    NSString *manager = [[PackageManagerSelector shared]
        nameForIOSMajorVersion:version];

    _lastSummary = [NSString stringWithFormat:
        @"CONFIGURATION SAVED\n\n"
         "Device: %@\n"
         "Secondary iOS major version: %ld\n"
         "Package manager preference: %@\n"
         "Root path: %@\n\n"
         "This records the configuration only. It does not install iOS, "
         "install %@, modify partitions, or enable dual-booting.",
         deviceIdentifier,
         (long)version,
         manager,
         rootPath,
         manager];

    return YES;
}

- (NSString *)installationSummary {
    return _lastSummary ?: @"No installation configuration is available.";
}

@end
