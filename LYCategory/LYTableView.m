#import "LYTableView.h"

@implementation UITableView (LYTableViewCell)
- (void)delete_path:(NSIndexPath*)path animation:(UITableViewRowAnimation)animation_delete
{
	[self beginUpdates];
	[self deleteRowsAtIndexPaths:[NSArray arrayWithObjects:path, nil] withRowAnimation:animation_delete];
	[self endUpdates];
}
@end
