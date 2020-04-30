#import "HBLinkTableCell.h"
#import <Preferences/PSSpecifier.h>
#import <UIKit/UIColor+Private.h>
#import <UIKit/UIImage+Private.h>
#import <version.h>

@implementation HBLinkTableCell

- (instancetype)initWithStyle:(UITableViewCellStyle)style reuseIdentifier:(NSString *)reuseIdentifier specifier:(PSSpecifier *)specifier {
	self = [super initWithStyle:UITableViewCellStyleSubtitle reuseIdentifier:reuseIdentifier specifier:specifier];

	if (self) {
		_isBig = specifier.properties[@"big"] && ((NSNumber *)specifier.properties[@"big"]).boolValue;

		self.selectionStyle = UITableViewCellSelectionStyleBlue;

		UIImageView *imageView = [[UIImageView alloc] initWithImage:[UIImage imageNamed:@"safari" inBundle:globalBundle]];
		if (IS_IOS_OR_NEWER(iOS_7_0)) {
			imageView.image = [imageView.image imageWithRenderingMode:UIImageRenderingModeAlwaysTemplate];
		}
		if (@available(iOS 13.0, *)) {
			if (IS_IOS_OR_NEWER(iOS_13_0)) {
				imageView.tintColor = [UIColor systemGray3Color];
			}
		}
		self.accessoryView = imageView;

		self.detailTextLabel.numberOfLines = _isBig ? 0 : 1;
		self.detailTextLabel.text = specifier.properties[@"subtitle"] ?: @"";
		if (IS_IOS_OR_NEWER(iOS_13_0)) {
			if (@available(iOS 13.0, *)) {
				self.detailTextLabel.textColor = [UIColor secondaryLabelColor];
			}
		} else {
			self.detailTextLabel.textColor = IS_IOS_OR_NEWER(iOS_7_0) ? [UIColor systemGrayColor] : [UIColor tableCellValue1BlueColor];
		}

		if (self.shouldShowAvatar) {
			CGFloat size = _isBig ? 38.f : 29.f;

			UIGraphicsBeginImageContextWithOptions(CGSizeMake(size, size), NO, [UIScreen mainScreen].scale);
			specifier.properties[@"iconImage"] = UIGraphicsGetImageFromCurrentImageContext();
			UIGraphicsEndImageContext();

			_avatarView = [[UIView alloc] initWithFrame:self.imageView.bounds];
			_avatarView.autoresizingMask = UIViewAutoresizingFlexibleWidth | UIViewAutoresizingFlexibleHeight;
			_avatarView.backgroundColor = [UIColor colorWithWhite:0.9f alpha:1];
			_avatarView.userInteractionEnabled = NO;
			_avatarView.clipsToBounds = YES;
			_avatarView.layer.cornerRadius = IS_IOS_OR_NEWER(iOS_7_0) ? size / 2 : 4.f;
			[self.imageView addSubview:_avatarView];

			if (specifier.properties[@"initials"]) {
				_avatarView.backgroundColor = [UIColor colorWithWhite:0.8f alpha:1];

				UILabel *label = [[UILabel alloc] initWithFrame:_avatarView.bounds];
				label.autoresizingMask = UIViewAutoresizingFlexibleWidth | UIViewAutoresizingFlexibleHeight;
				label.font = [UIFont systemFontOfSize:13.f];
				label.textAlignment = NSTextAlignmentCenter;
				label.textColor = [UIColor whiteColor];
				label.text = specifier.properties[@"initials"];
				[_avatarView addSubview:label];
			} else {
				_avatarImageView = [[UIImageView alloc] initWithFrame:_avatarView.bounds];
				_avatarImageView.autoresizingMask = UIViewAutoresizingFlexibleWidth | UIViewAutoresizingFlexibleHeight;
				_avatarImageView.alpha = 0;
				_avatarImageView.userInteractionEnabled = NO;
				_avatarImageView.layer.minificationFilter = kCAFilterTrilinear;
				[_avatarView addSubview:_avatarImageView];

				[self loadAvatarIfNeeded];
			}
		}
	}

	return self;
}

#pragma mark - Avatar

- (UIImage *)avatarImage {
	return _avatarImageView.image;
}

- (void)setAvatarImage:(UIImage *)avatarImage {
	// set the image on the image view
	_avatarImageView.image = avatarImage;

	// if we haven’t faded in yet
	if (_avatarImageView.alpha == 0) {
		// do so now
		[UIView animateWithDuration:0.15 animations:^{
			_avatarImageView.alpha = 1;
		}];
	}
}

- (BOOL)shouldShowAvatar {
	// if showAvatar is non-nil and YES, use that value. otherwise, if initials
	// is non-nil, return YES
	return (self.specifier.properties[@"showAvatar"] && ((NSNumber *)self.specifier.properties[@"showAvatar"]).boolValue) ||
		self.specifier.properties[@"initials"];
}

- (void)loadAvatarIfNeeded {
	// stub for subclasses
}

@end
