#import <Foundation/Foundation.h>
#import "LYArray.h"

@interface NSMutableArray (LYMutableArray)
- (void)add_objects:(id) firstObject, ...;
- (void)add_array:(id) firstObject, ...;
- (BOOL)add_object_unique:(id)obj;
- (BOOL)insert_unique:(id)obj at:(int)index;
- (void)sort_by_key:(NSString*)key ascending:(BOOL)b;
@end
