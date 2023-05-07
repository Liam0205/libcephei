#import "HBPackageTableCell.h"
#import "HBPackage.h"
#import "../NSDictionary+HBAdditions.h"
#import <Preferences/PSSpecifier.h>
#import <UIKit/UIImage+Private.h>
#import <version.h>

@implementation HBPackageTableCell {
	NSString *_identifier;
	NSString *_repo;
}

- (instancetype)initWithStyle:(UITableViewCellStyle)style reuseIdentifier:(NSString *)reuseIdentifier specifier:(PSSpecifier *)specifier {
	_identifier = [specifier.properties[@"packageIdentifier"] copy];
	_repo = [specifier.properties[@"packageRepository"] copy];

	NSParameterAssert(_identifier);

	if (specifier.properties[@"iconURL"] == nil) {
		NSURL *iconURL = [NSURL URLWithString:[@"https://api.canister.me/v1/community/packages?" stringByAppendingString:@{
			@"id": _identifier,
			@"content": @"packageIcon",
			@"redirect": @"true"
		}.hb_queryString]];

		NSString *iconField = getFieldForPackage(_identifier, @"Icon");
		if (iconField && ![iconField isEqualToString:@""]) {
			NSURL *maybeIconURL = [NSURL URLWithString:iconField];
			if (maybeIconURL != nil && (!maybeIconURL.isFileURL || [maybeIconURL checkResourceIsReachableAndReturnError:nil])) {
				iconURL = maybeIconURL;
			}
		}

		specifier.properties[@"iconURL"] = iconURL;
	}

	self = [super initWithStyle:UITableViewCellStyleSubtitle reuseIdentifier:reuseIdentifier specifier:specifier];

	if (self) {
		UIImageView *imageView = (UIImageView *)self.accessoryView;
		imageView.image = [UIImage systemImageNamed:@"shippingbox"];
		[imageView sizeToFit];
	}

	return self;
}

- (BOOL)shouldShowIcon {
	return YES;
}

@end
