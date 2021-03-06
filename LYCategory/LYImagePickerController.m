#import "LYImagePickerController.h"

@implementation UIImagePickerController (LYImagePickerController)

- (void)set_image:(UIImageView*)an_image
{
	[self associate:@"ly-image" with:an_image];
}

- (void)set_delegate:(id)a_delegate
{
	[self associate:@"ly_delegate" with:a_delegate];
}

- (void)get_image_nav:(UINavigationController*)nav image:(UIImageView*)view
{
	[self get_image_nav:nav image:view delegate:nil];
}

- (void)get_image_nav:(UINavigationController*)nav image:(UIImageView*)view delegate:(id)obj
{
	[self associate:@"ly_delegate" with:obj];

	//	self.allowsEditing = YES;
	self.delegate = (UIImagePickerController<UINavigationControllerDelegate, UIImagePickerControllerDelegate>*)self;

	if ([UIImagePickerController isSourceTypeAvailable:UIImagePickerControllerSourceTypePhotoLibrary] == NO)
	{
		[@"Sorry, photo library is not supported on this device." show_alert_title:@"Library Not Available"];
	}
	else
	{
		//self.sourceType = UIImagePickerControllerSourceTypePhotoLibrary;
		if (is_phone())
		{
			[nav presentModalViewController:self animated:YES];
			[self associate:@"ly_nav" with:nav];
		}
		else
		{
			id	popover_controller = [NSClassFromString(@"UIPopoverController") class];
			if ((popover_controller != nil) && (is_pad()))
				[self associate:@"ly_pop" with:[[popover_controller alloc] initWithContentViewController:self]];
			//	NSLog(@"pop: %@", [self associated:@"ly_pop"]);
			UIView* parent = [self associated:@"ly-parent"];
			if (parent == nil)
				parent = nav.view;
			//	NSLog(@"parent frame: %@", NSStringFromCGRect(parent.frame));
			[[self associated:@"ly_pop"] presentPopoverFromRect:parent.frame inView:nav.view permittedArrowDirections:UIPopoverArrowDirectionAny animated:YES];
		}
	}

	[self associate:@"ly-image" with:view];
}

- (void)imagePickerController:(UIImagePickerController *)a_picker didFinishPickingMediaWithInfo:(NSDictionary *)info
{
	UIImage* image = [info valueForKey:@"UIImagePickerControllerEditedImage"];
	if (image == nil)
		image = [info valueForKey:@"UIImagePickerControllerOriginalImage"];
	[LYLoading show];
	image = [image apply_orientation];
	NSLog(@"image size 1: %@", NSStringFromCGSize(image.size));
	//image = [image image_with_size_aspect_fill:CGSizeMake([ly screen_width], [ly screen_height])];
	CGFloat ratio = image.size.width / [ly screen_width] / [[UIScreen mainScreen] scale];
	if (ratio < 1)
		ratio = 1;
	image = [UIImage imageWithCGImage:image.CGImage scale:ratio orientation:image.imageOrientation];
	NSLog(@"image size 2: %@", NSStringFromCGSize(image.size));
	//	NSLog(@"orientation: %i", image.imageOrientation);
	[[self associated:@"ly-image"] setImage:image];
	[LYLoading hide];
	[self ly_dismiss];

	if ([self associated:@"ly_delegate"] != nil)
	   [[self associated:@"ly_delegate"] performSelector:@selector(imagePickerController:didFinishPickingMediaWithInfo:) withObject:a_picker withObject:info];
	//else [self release];
}

- (void)imagePickerControllerDidCancel:(UIImagePickerController *)a_picker
{
	[self ly_dismiss];
	if ([self associated:@"ly_delegate"] != nil)
	   [[self associated:@"ly_delegate"] performSelector:@selector(imagePickerControllerDidCancel:) withObject:a_picker];
	//else [self release];
}

- (void)ly_dismiss
{
	if (is_phone())
	{
		[[self associated:@"ly_nav"] dismissModalViewControllerAnimated:YES];
	}
	else
	{
		[[self associated:@"ly_pop"] dismissPopoverAnimated:YES];
		//[[self associated:@"ly_pop"] release];
	}
}

#ifdef LY_ENABLE_CATEGORY_NAVIGATIONCONTROLLER_LANDSCAPE
- (BOOL)shouldAutorotateToInterfaceOrientation:(UIInterfaceOrientation)interfaceOrientation
{
	return (interfaceOrientation == UIInterfaceOrientationLandscapeRight);
}
#endif
#ifdef LY_ENABLE_CATEGORY_NAVIGATIONCONTROLLER_ROTATE
- (BOOL)shouldAutorotateToInterfaceOrientation:(UIInterfaceOrientation)interfaceOrientation
{
	//	NSLog(@"VIEW should rotate: %i, %f, %f", interfaceOrientation, screen_width(), screen_height());
	if (UI_USER_INTERFACE_IDIOM() == UIUserInterfaceIdiomPhone)
	{
		if (interfaceOrientation == UIInterfaceOrientationPortrait)
			return YES;
		else
#ifdef LY_ENABLE_CATEGORY_NAVIGATIONCONTROLLER_ROTATEPHONE
			return YES;
#else
			return NO;
#endif
	}
	else
		return YES;
}
#endif

@end
