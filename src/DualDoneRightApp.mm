#import "DualDoneRightApp.h"
#import "DeviceCompatibility.h"
#import "FirmwareManager.h"
#import "BootManager.h"
#import "RecoveryManager.h"
#import "PackageManagerSelector.h"
#import "SecondarySystemConfig.h"
#import "SecondarySystemInstaller.h"
#import "BootBackend.h"
#import <QuartzCore/QuartzCore.h>

@interface DDDRHomeViewController : UIViewController
@end

@implementation DualDoneRightApp

- (BOOL)application:(UIApplication *)application
didFinishLaunchingWithOptions:(NSDictionary *)launchOptions {

    self.window = [[UIWindow alloc] initWithFrame:[UIScreen mainScreen].bounds];

    DDDRHomeViewController *home = [DDDRHomeViewController new];
    UINavigationController *navigation =
        [[UINavigationController alloc] initWithRootViewController:home];

    self.window.rootViewController = navigation;
    [self.window makeKeyAndVisible];

    return YES;
}

@end

@implementation DDDRHomeViewController {
    UILabel *_deviceLabel;
    UILabel *_packageManagerLabel;
    UILabel *_statusLabel;
    UITextField *_versionField;
    UITextField *_rootPathField;
}

- (void)viewDidLoad {
    [super viewDidLoad];

    self.title = @"DualDoneRight";
    self.view.backgroundColor = [UIColor whiteColor];

    UIScrollView *scroll =
        [[UIScrollView alloc] initWithFrame:self.view.bounds];

    scroll.autoresizingMask =
        UIViewAutoresizingFlexibleWidth | UIViewAutoresizingFlexibleHeight;

    [self.view addSubview:scroll];

    CGFloat width = CGRectGetWidth(self.view.bounds);

    UIView *content =
        [[UIView alloc] initWithFrame:CGRectMake(0, 0, width, 800)];

    content.autoresizingMask = UIViewAutoresizingFlexibleWidth;
    [scroll addSubview:content];
    scroll.contentSize = content.bounds.size;

    UILabel *heading = [[UILabel alloc]
        initWithFrame:CGRectMake(20, 18, width - 40, 40)];

    heading.text = @"DualDoneRight";
    heading.font = [UIFont boldSystemFontOfSize:29];
    heading.textAlignment = NSTextAlignmentCenter;
    [content addSubview:heading];

    UILabel *subtitle = [[UILabel alloc]
        initWithFrame:CGRectMake(20, 58, width - 40, 32)];

    subtitle.text = @"On-device dual-boot manager";
    subtitle.font = [UIFont systemFontOfSize:15];
    subtitle.textColor = [UIColor darkGrayColor];
    subtitle.textAlignment = NSTextAlignmentCenter;
    [content addSubview:subtitle];

    _deviceLabel = [self cardAtY:100
                          height:100
                           width:width
                          parent:content];

    _deviceLabel.text = [[DeviceCompatibility shared] summary];

    UILabel *versionTitle = [[UILabel alloc]
        initWithFrame:CGRectMake(20, 215, width - 40, 24)];

    versionTitle.text = @"Secondary iOS major version";
    versionTitle.font = [UIFont boldSystemFontOfSize:15];
    [content addSubview:versionTitle];

    _versionField = [[UITextField alloc]
        initWithFrame:CGRectMake(20, 243, width - 40, 44)];

    _versionField.borderStyle = UITextBorderStyleRoundedRect;
    _versionField.placeholder = @"For example: 10 or 12";
    _versionField.keyboardType = UIKeyboardTypeNumberPad;
    _versionField.text = @"10";
    [content addSubview:_versionField];

    UILabel *pathTitle = [[UILabel alloc]
        initWithFrame:CGRectMake(20, 296, width - 40, 24)];

    pathTitle.text = @"Existing secondary root path";
    pathTitle.font = [UIFont boldSystemFontOfSize:15];
    [content addSubview:pathTitle];

    _rootPathField = [[UITextField alloc]
        initWithFrame:CGRectMake(20, 324, width - 40, 44)];

    _rootPathField.borderStyle = UITextBorderStyleRoundedRect;
    _rootPathField.placeholder = @"/path/to/secondary/root";
    _rootPathField.autocapitalizationType = UITextAutocapitalizationTypeNone;
    _rootPathField.autocorrectionType = UITextAutocorrectionTypeNo;
    _rootPathField.keyboardType = UIKeyboardTypeURL;
    [content addSubview:_rootPathField];

    [self addButton:@"Detect Package Manager"
                  y:380 width:width parent:content
             action:@selector(detectPackageManager)];

    _packageManagerLabel = [self cardAtY:435
                                  height:85
                                   width:width
                                  parent:content];

    _packageManagerLabel.text =
        @"Package manager: not selected\n\n"
         "iOS 1–8: Cydia\n"
         "iOS 9–12: Zebra";

    [self addButton:@"Save Secondary Configuration"
                  y:530 width:width parent:content
             action:@selector(saveConfiguration)];

    [self addButton:@"Check Boot Backend"
                  y:586 width:width parent:content
             action:@selector(checkBootBackend)];

    [self addButton:@"Firmware Requirements"
                  y:642 width:width parent:content
             action:@selector(showFirmware)];

    [self addButton:@"Recovery & Safety"
                  y:698 width:width parent:content
             action:@selector(showRecovery)];

    _statusLabel = [[UILabel alloc]
        initWithFrame:CGRectMake(20, 755, width - 40, 80)];

    _statusLabel.numberOfLines = 0;
    _statusLabel.font = [UIFont systemFontOfSize:12];
    _statusLabel.textColor = [UIColor darkGrayColor];
    _statusLabel.textAlignment = NSTextAlignmentCenter;
    _statusLabel.text =
        @"Boot engine unavailable. No firmware or partition changes are made.";

    [content addSubview:_statusLabel];

    [self detectPackageManager];
    [self checkBootBackend];
}

- (UILabel *)cardAtY:(CGFloat)y
              height:(CGFloat)height
               width:(CGFloat)width
              parent:(UIView *)parent {

    UILabel *label = [[UILabel alloc]
        initWithFrame:CGRectMake(20, y, width - 40, height)];

    label.autoresizingMask = UIViewAutoresizingFlexibleWidth;
    label.numberOfLines = 0;
    label.font = [UIFont systemFontOfSize:13];
    label.textColor = [UIColor blackColor];
    label.backgroundColor = [UIColor colorWithWhite:0.95 alpha:1.0];
    label.layer.cornerRadius = 10;
    label.layer.masksToBounds = YES;

    [parent addSubview:label];
    return label;
}

- (void)addButton:(NSString *)title
                y:(CGFloat)y
            width:(CGFloat)width
           parent:(UIView *)parent
           action:(SEL)action {

    UIButton *button = [UIButton buttonWithType:UIButtonTypeSystem];

    button.frame = CGRectMake(20, y, width - 40, 44);
    button.autoresizingMask = UIViewAutoresizingFlexibleWidth;
    button.backgroundColor = [UIColor colorWithWhite:0.93 alpha:1.0];
    button.layer.cornerRadius = 9;

    [button setTitle:title forState:UIControlStateNormal];
    button.titleLabel.font = [UIFont systemFontOfSize:15];

    [button addTarget:self
               action:action
     forControlEvents:UIControlEventTouchUpInside];

    [parent addSubview:button];
}

- (NSInteger)selectedIOSMajorVersion {
    return _versionField.text.integerValue;
}

- (NSString *)currentDeviceIdentifier {
    return [[DeviceCompatibility shared] deviceModel];
}

- (void)detectPackageManager {
    [_versionField resignFirstResponder];

    NSInteger version = [self selectedIOSMajorVersion];

    NSString *summary = [[PackageManagerSelector shared]
        compatibilitySummaryForIOSMajorVersion:version];

    _packageManagerLabel.text = summary;
}

- (void)saveConfiguration {
    [_versionField resignFirstResponder];
    [_rootPathField resignFirstResponder];

    NSInteger version = [self selectedIOSMajorVersion];
    NSString *rootPath = [_rootPathField.text
        stringByTrimmingCharactersInSet:
            [NSCharacterSet whitespaceAndNewlineCharacterSet]];

    NSError *error = nil;

    BOOL success = [[SecondarySystemInstaller shared]
        configureSecondarySystemAtRootPath:rootPath
                          iosMajorVersion:version
                          deviceIdentifier:[self currentDeviceIdentifier]
                                     error:&error];

    if (success) {
        _statusLabel.text =
            [[SecondarySystemInstaller shared] installationSummary];

        [self showMessage:@"Configuration Saved"
                  message:_statusLabel.text];
    } else {
        [self showMessage:@"Configuration Not Saved"
                  message:error.localizedDescription
                      ?: @"The configuration could not be saved."];
    }
}

- (void)checkBootBackend {
    NSInteger version = [self selectedIOSMajorVersion];

    _statusLabel.text = [[BootBackend shared]
        availabilitySummaryForDevice:[self currentDeviceIdentifier]
                     iosMajorVersion:version];
}

- (void)showFirmware {
    [self showMessage:@"Firmware Requirements"
              message:[[FirmwareManager shared] requirementsSummary]];
}

- (void)showRecovery {
    [self showMessage:@"Recovery & Safety"
              message:[[RecoveryManager shared] safetySummary]];
}

- (void)showMessage:(NSString *)title message:(NSString *)message {
    UIAlertController *alert =
        [UIAlertController alertControllerWithTitle:title
                                            message:message
                                     preferredStyle:UIAlertControllerStyleAlert];

    [alert addAction:[UIAlertAction actionWithTitle:@"OK"
                                             style:UIAlertActionStyleDefault
                                           handler:nil]];

    [self presentViewController:alert animated:YES completion:nil];
}

@end
