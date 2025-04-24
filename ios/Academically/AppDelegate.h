#import <React/RCTBridgeDelegate.h>
#import <UIKit/UIKit.h>
#import <React/RCTRootView.h>

@interface AppDelegate : UIResponder <UIApplicationDelegate, RCTBridgeDelegate>

@property (nonatomic, strong) UIWindow *window;

- (void)customizeRootView:(RCTRootView *)rootView;

@end
