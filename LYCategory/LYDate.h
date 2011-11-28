#import <Foundation/Foundation.h>

/*
	//	use this instead of old methods, it handles different calendars
	[NSDateFormatter localizedStringFromDate:date_start 
								   dateStyle:NSDateFormatterLongStyle 
								   timeStyle:NSDateFormatterNoStyle];
*/

@interface NSDate (LYDate)
+ (NSDate*)date_from_string:(NSString*)string format:(NSString*)format;
+ (NSDate*)date_from_date:(NSDate*)date time:(NSDate*)time;
+ (NSDate*)yesterday;
+ (NSDate*)tomorrow;
- (NSDate*)yesterday;
- (NSDate*)tomorrow;
- (NSDate*)next_week;
- (NSDate*)next_fortnight;
- (NSDate*)next_month;
- (NSDate*)next_year;
- (BOOL)is_same_date:(NSDate*)date1;
- (BOOL)is_same_month:(NSDate*)date1;
@end
