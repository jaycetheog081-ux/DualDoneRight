#import "SecondarySystemInstaller.h"
#import "SecondarySystemConfig.h"
#import "PackageManagerSelector.h"

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
            @"No secondary system has been configured.";
    }

    return self;
}

- (BOOL)validateSecondaryRootPath:(NSString *)rootPath
                            error:(NSError **)error {
    BOOL isDirectory = NO;

    if (rootPath.length == 0 || ![rootPath isAbsolutePath]) {
        if (error) {
            *error = [NSError errorWithDomain:DDDRInstallerErrorDomain
                                         code:1
                                     userInfo:@{
                NSLocalizedDescriptionKey:
                    @"Enter an absolute path to an existing directory."
            }];
        }
        return NO;
    }

    BOOL exists = [[NSFileManager defaultManager]
        fileExistsAtPath:rootPath
            isDirectory:&isDirectory];

    if (!exists || !isDirectory) {
        if (error) {
            *error = [NSError errorWithDomain:DDDRInstallerErrorDomain
                                         code:2
                                     userInfo:@{
                NSLocalizedDescriptionKey:
                    @"The specified root directory does not exist. "
                     "This prototype does not create partitions or install firmware."
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

    NSString *documents = NSSearchPathForDirectoriesInDomains(
        NSDocumentDirectory,
        NSUserDomainMask,
        YES
    ).firstObject;

    if (documents.length == 0) {
        if (error) {
            *error = [NSError errorWithDomain:DDDRInstallerErrorDomain
                                         code:3
                                     userInfo:@{
                NSLocalizedDescriptionKey:
                    @"Unable to locate the app's Documents directory."
            }];
        }
        return NO;
    }

    NSURL *configURL = [NSURL fileURLWithPath:
        [documents stringByAppendingPathComponent:@"SecondarySystem.plist"]];

    if (![config saveToURL:configURL error:error]) {
        return NO;
    }

    NSString *manager = [[PackageManagerSelector shared]
        nameForIOSMajorVersion:version];

    _lastSummary = [NSString stringWithFormat:
        @"CONFIGURATION SAVED\n\n"
         "Device: %@\n"
         "Secondary iOS major version: %ld\n"
         "Package manager preference: %@\n"
         "Root path: %@\n"
         "Configuration: %@\n\n"
         "No firmware was installed. No partitions were modified. "
         "The package manager has not been installed.",
         deviceIdentifier,
         (long)version,
         manager,
         rootPath,
         configURL.path];

    return YES;
}

- (NSString *)installationSummary {
    return _lastSummary ?: @"No configuration is available.";
}

@end
