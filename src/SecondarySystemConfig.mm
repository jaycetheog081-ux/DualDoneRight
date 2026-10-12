#import "SecondarySystemConfig.h"
#import "PackageManagerSelector.h"

static NSString * const DDDRConfigErrorDomain =
    @"com.dualdoneright.config";

@implementation SecondarySystemConfig

+ (instancetype)shared {
    static SecondarySystemConfig *instance;
    static dispatch_once_t onceToken;

    dispatch_once(&onceToken, ^{
        instance = [[SecondarySystemConfig alloc] init];
    });

    return instance;
}

- (instancetype)init {
    self = [super init];

    if (self) {
        [self reset];
    }

    return self;
}

- (void)reset {
    self.iosMajorVersion = 0;
    self.deviceIdentifier = @"";
    self.systemRootPath = @"";
    self.packageManagerName = @"";
}

- (BOOL)configureForIOSMajorVersion:(NSInteger)version
                   deviceIdentifier:(NSString *)device
                      systemRootPath:(NSString *)rootPath
                              error:(NSError **)error {

    if (version < 1 || version > 12) {
        if (error) {
            *error = [NSError errorWithDomain:DDDRConfigErrorDomain
                                         code:1
                                     userInfo:@{
                NSLocalizedDescriptionKey:
                    @"Choose a secondary iOS version from 1 through 12."
            }];
        }
        return NO;
    }

    if (device.length == 0 || rootPath.length == 0) {
        if (error) {
            *error = [NSError errorWithDomain:DDDRConfigErrorDomain
                                         code:2
                                     userInfo:@{
                NSLocalizedDescriptionKey:
                    @"A device identifier and secondary root path are required."
            }];
        }
        return NO;
    }

    NSString *manager =
        [[PackageManagerSelector shared] nameForIOSMajorVersion:version];

    if ([manager hasPrefix:@"Unsupported"]) {
        if (error) {
            *error = [NSError errorWithDomain:DDDRConfigErrorDomain
                                         code:3
                                     userInfo:@{
                NSLocalizedDescriptionKey:
                    @"No package manager is configured for this iOS version."
            }];
        }
        return NO;
    }

    self.iosMajorVersion = version;
    self.deviceIdentifier = device;
    self.systemRootPath = rootPath;
    self.packageManagerName = manager;

    return YES;
}

- (NSDictionary *)dictionaryRepresentation {
    return @{
        @"iosMajorVersion": @(self.iosMajorVersion),
        @"deviceIdentifier": self.deviceIdentifier ?: @"",
        @"systemRootPath": self.systemRootPath ?: @"",
        @"packageManagerName": self.packageManagerName ?: @"",
        @"configurationVersion": @1
    };
}

- (BOOL)saveToURL:(NSURL *)url error:(NSError **)error {
    if (!url) {
        if (error) {
            *error = [NSError errorWithDomain:DDDRConfigErrorDomain
                                         code:4
                                     userInfo:@{
                NSLocalizedDescriptionKey: @"Configuration URL is missing."
            }];
        }
        return NO;
    }

    NSData *data = [NSPropertyListSerialization
        dataWithPropertyList:[self dictionaryRepresentation]
                      format:NSPropertyListXMLFormat_v1_0
                     options:0
                       error:error];

    if (!data) {
        return NO;
    }

    return [data writeToURL:url options:NSDataWritingAtomic error:error];
}

- (BOOL)loadFromURL:(NSURL *)url error:(NSError **)error {
    NSData *data = [NSData dataWithContentsOfURL:url options:0 error:error];

    if (!data) {
        return NO;
    }

    id object = [NSPropertyListSerialization
        propertyListWithData:data
                     options:NSPropertyListImmutable
                      format:NULL
                       error:error];

    if (![object isKindOfClass:[NSDictionary class]]) {
        if (error) {
            *error = [NSError errorWithDomain:DDDRConfigErrorDomain
                                         code:5
                                     userInfo:@{
                NSLocalizedDescriptionKey:
                    @"The configuration file is invalid."
            }];
        }
        return NO;
    }

    NSDictionary *dictionary = (NSDictionary *)object;

    self.iosMajorVersion =
        [dictionary[@"iosMajorVersion"] respondsToSelector:@selector(integerValue)]
            ? [dictionary[@"iosMajorVersion"] integerValue] : 0;

    self.deviceIdentifier = dictionary[@"deviceIdentifier"] ?: @"";
    self.systemRootPath = dictionary[@"systemRootPath"] ?: @"";
    self.packageManagerName = dictionary[@"packageManagerName"] ?: @"";

    return YES;
}

@end
