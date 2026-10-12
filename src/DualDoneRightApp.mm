#import "DualDoneRightApp.h"
#import "DeviceCompatibility.h"
#import "FirmwareManager.h"
#import "BootManager.h"
#import "RecoveryManager.h"
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
    UILabel *_bootLabel;
}

- (void)viewDidLoad {
    [super viewDidLoad];

    self.title = @"DualDoneRight";
    self.view.backgroundColor = [UIColor whiteColor];

    UIScrollView *scroll = [[UIScrollView alloc] initWithFrame:self.view.bounds];
    scroll.autoresizingMask =
        UIViewAutoresizingFlexibleWidth | UIViewAutoresizingFlexibleHeight;
    [self.view addSubview:scroll];

    CGFloat width = CGRectGetWidth(self.view.bounds);

    UIView *content = [[UIView alloc] initWithFrame:CGRectMake(0, 0, width, 600)];
    content.autoresizingMask = UIViewAutoresizingFlexibleWidth;
    [scroll addSubview:content];
    scroll.contentSize = content.bounds.size;

    UILabel *heading = [[UILabel alloc]
        initWithFrame:CGRectMake(20, 20, width - 40, 42)];
    heading.text = @"DualDoneRight";
    heading.font = [UIFont boldSystemFontOfSize:30];
    heading.textAlignment = NSTextAlignmentCenter;
    [content addSubview:heading];

    UILabel *subtitle = [[UILabel alloc]
        initWithFrame:CGRectMake(20, 65, width - 40, 30)];
    subtitle.text = @"Dual-boot management";
    subtitle.font = [UIFont systemFontOfSize:16];
    subtitle.textColor = [UIColor darkGrayColor];
    subtitle.textAlignment = NSTextAlignmentCenter;
    [content addSubview:subtitle];

    _deviceLabel = [self cardAtY:110 height:115 width:width parent:content];
    _deviceLabel.text = [[DeviceCompatibility shared] summary];

    _bootLabel = [self cardAtY:240 height:100 width:width parent:content];
    _bootLabel.text = [[BootManager shared] statusSummary];

    [self addButton:@"Refresh Device Status"
                  y:350 width:width parent:content
             action:@selector(refreshStatus)];

    [self addButton:@"Firmware Requirements"
                  y:410 width:width parent:content
             action:@selector(showFirmware)];

    [self addButton:@"Recovery & Safety"
                  y:470 width:width parent:content
             action:@selector(showRecovery)];

    UILabel *footer = [[UILabel alloc]
        initWithFrame:CGRectMake(20, 530, width - 40, 55)];
    footer.numberOfLines = 0;
    footer.font = [UIFont systemFontOfSize:12];
    footer.textColor = [UIColor darkGrayColor];
    footer.textAlignment = NSTextAlignmentCenter;
    footer.text = @"Boot engine is not implemented yet. No partitions or boot settings are modified.";
    [content addSubview:footer];
}

- (UILabel *)cardAtY:(CGFloat)y
              height:(CGFloat)height
               width:(CGFloat)width
              parent:(UIView *)parent {

    UILabel *label = [[UILabel alloc]
        initWithFrame:CGRectMake(20, y, width - 40, height)];

    label.autoresizingMask = UIViewAutoresizingFlexibleWidth;
    label.numberOfLines = 0;
    label.font = [UIFont systemFontOfSize:14];
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

    button.frame = CGRectMake(20, y, width - 40, 46);
    button.autoresizingMask = UIViewAutoresizingFlexibleWidth;
    button.backgroundColor = [UIColor colorWithWhite:0.93 alpha:1.0];
    button.layer.cornerRadius = 9;

    [button setTitle:title forState:UIControlStateNormal];
    button.titleLabel.font = [UIFont systemFontOfSize:16];

    [button addTarget:self
               action:action
     forControlEvents:UIControlEventTouchUpInside];

    [parent addSubview:button];
}

- (void)refreshStatus {
    _deviceLabel.text = [[DeviceCompatibility shared] summary];
    _bootLabel.text = [[BootManager shared] statusSummary];
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
