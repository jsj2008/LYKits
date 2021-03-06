#import <objc/message.h>
#import <UIKit/UIKit.h>
#import "LYScrollTabController.h"
#import "LYTableViewProvider.h"
#import "LYButtonMatrixController.h"
#import "LYKeyboardMatrixController.h"
#import "LYAsyncImageView.h"
#import "LYBrowserController.h"
#import "LYImagePickerController.h"
#import "LYShareController.h"
#import "LYTextAlertView.h"
#import "LYLoadingViewController.h"
#import "LYPDFViewController.h"
#import "LYMiniAppsController.h"
#import "LY3DImageView.h"
#import "LYListController.h"
//#import "LYTableController.h"
#import "LYPickerViewProvider.h"
#import "LYFlipImageView.h"
#import "LYSpinImageView.h"

BOOL CGPointInRect(CGPoint point, CGRect rect);
UIInterfaceOrientation get_interface_orientation();
BOOL is_interface_portrait();
BOOL is_interface_landscape();
CGFloat get_width(CGFloat width);
CGFloat get_height(CGFloat height);
CGFloat screen_width(void);
CGFloat screen_height(void);
CGFloat screen_max(void);
UIView* ly_alloc_view_loading(void);

/*
 *
 * LYScrollTabController
 * 		scrollable tab controller
 *
 * LYTableViewProvider
 * 		advanced data source of UITableView
 * 		best practise: static tables (see project iphone/pacard)
 *
 * LYButtonMatrixController
 * 		movable button matrix
 * 		can be added to a scroll view
 *
 * LYKeyboardMatrixController
 * 		customized keyboard that supports dovrak layout, etc.
 *
 * LYAsyncImageView
 * 		multiple-thread downloading
 *
 * LYBrowserController
 * 		in-app internet browser
 *
 * LYImagePickerController
 * 		image picker warp
 *
 * LYShareController
 * 		text sharing via mail, sms, facebook, etc.
 *
 * LYTextAlertView
 * 		alert view that contains UITextFields
 *
 * LYLoadingViewController
 * 		customizable loading view
 *
 */

#if 0
@interface LYMiniApps: LYSingletonClass
{
	UINavigationController*	nav;
	BOOL					status_bar_hidden;
}
@property (nonatomic, retain) UINavigationController*		nav;
+ (id)shared;
- (id)initWithNavigationController:(UINavigationController*)a_nav;
- (void)show_flashlight:(UIColor*)color;
- (void)show_image:(NSString*)filename;
@end
#endif

@interface LYRotateViewController: UIViewController
@end
