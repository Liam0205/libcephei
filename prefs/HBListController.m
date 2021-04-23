#import "HBListController.h"
#import "HBListController+Actions.h"
#import "HBListController+Deprecated.h"
#import "HBAppearanceSettings.h"
#import "HBLinkTableCell.h"
#import "HBPackageTableCell.h"
#import "HBTwitterCell.h"
#import "HBTwitterAPIClient.h"
#import "PSListController+HBTintAdditions.h"
#import "UINavigationItem+HBTintAdditions.h"
#import "Symbols.h"
#import <Preferences/PSSpecifier.h>
#import <version.h>

@interface PSListController ()

- (UINavigationController *)_hb_realNavigationController;
- (void)_hb_getAppearance;

@end

@interface HBListController (DeprecatedPrivate)

- (void)_handleDeprecatedAppearanceMethods;

@end

@implementation HBListController {
	NSArray *__deprecatedAppearanceMethodsInUse;
}

#pragma mark - Constants

+ (NSString *)hb_specifierPlist {
	return nil;
}

#pragma mark - Loading specifiers

- (void)_loadSpecifiersFromPlistIfNeeded {
	if (_specifiers || ![self.class hb_specifierPlist]) {
		return;
	}

	_specifiers = [self loadSpecifiersFromPlistName:[self.class hb_specifierPlist] target:self];
}

- (NSArray *)specifiers {
	[self _loadSpecifiersFromPlistIfNeeded];
	return _specifiers;
}

- (NSMutableArray *)loadSpecifiersFromPlistName:(NSString *)plistName target:(PSListController *)target {
	// Override the loading mechanism so we can add additional features.
	NSMutableArray *specifiers = [super loadSpecifiersFromPlistName:plistName target:target];
	return [self _hb_configureSpecifiers:specifiers];
}

- (NSMutableArray *)loadSpecifiersFromPlistName:(NSString *)plistName target:(PSListController *)target bundle:(NSBundle *)bundle {
	// Override the loading mechanism so we can add additional features.
	NSMutableArray *specifiers = [super loadSpecifiersFromPlistName:plistName target:target bundle:bundle];
	return [self _hb_configureSpecifiers:specifiers];
}

- (NSMutableArray *)_hb_configureSpecifiers:(NSMutableArray *)specifiers {
	NSMutableArray *specifiersToRemove = [NSMutableArray array];
	NSMutableArray <NSString *> *twitterUsernames = [NSMutableArray array];
	NSMutableArray <NSString *> *twitterUserIDs = [NSMutableArray array];

	for (PSSpecifier *specifier in specifiers) {
		// Reimplementation of libprefs (from PreferenceLoader) pl_filter.
		// When there is 1 item in CoreFoundationVersion: This number is the minimum bound.
		// When there are 2 items in CoreFoundationVersion: First item is min bound, second is max bound.
		NSDictionary *filters = specifier.properties[@"pl_filter"];

		if (filters && filters[@"CoreFoundationVersion"]) {
			NSArray <NSNumber *> *versionFilter = filters[@"CoreFoundationVersion"];

			double min = versionFilter[0] ? ((NSNumber *)versionFilter[0]).doubleValue : DBL_MIN;
			double max = versionFilter.count > 1 && versionFilter[1] ? ((NSNumber *)versionFilter[1]).doubleValue : DBL_MAX;

			if (kCFCoreFoundationVersionNumber < min || kCFCoreFoundationVersionNumber >= max) {
				[specifiersToRemove addObject:specifier];
			}
		}

		// grab the cell class
		Class cellClass = specifier.properties[PSCellClassKey];

		// if it’s HBLinkTableCell, override the type and action to our own
		if ([cellClass isSubclassOfClass:HBLinkTableCell.class] && specifier.buttonAction == nil) {
			specifier.cellType = PSLinkCell;
			if ([cellClass isSubclassOfClass:HBPackageTableCell.class]) {
				specifier.buttonAction = @selector(hb_openPackage:);
			} else {
				specifier.buttonAction = @selector(hb_openURL:);
			}
			if ([cellClass isSubclassOfClass:HBTwitterCell.class]) {
				if (specifier.properties[@"userID"] != nil) {
					[twitterUserIDs addObject:specifier.properties[@"userID"]];
				} else if (specifier.properties[@"user"] != nil) {
					[twitterUsernames addObject:specifier.properties[@"user"]];
				}
			}
			if (!IS_IOS_OR_NEWER(iOS_8_0)) {
				specifier.controllerLoadAction = specifier.buttonAction;
			}
		}

		// Support for SF Symbols (system images)
		if (IS_IOS_OR_NEWER(iOS_13_0)) {
			if (@available(iOS 13, *)) {
				UIImage *iconImage = [self _hb_symbolImageFromDictionary:specifier.properties[@"iconImageSystem"]];
				if (iconImage != nil) {
					specifier.properties[@"iconImage"] = iconImage;
				}

				UIImage *leftImage = [self _hb_symbolImageFromDictionary:specifier.properties[@"leftImageSystem"]];
				if (leftImage != nil) {
					specifier.properties[@"leftImage"] = leftImage;
				}

				UIImage *rightImage = [self _hb_symbolImageFromDictionary:specifier.properties[@"rightImageSystem"]];
				if (rightImage != nil) {
					specifier.properties[@"rightImage"] = rightImage;
				}
			}
		}
	}

	// if we have specifiers to remove
	if (specifiersToRemove.count > 0) {
		// make a mutable copy of the specifiers
		NSMutableArray *newSpecifiers = [specifiers mutableCopy];

		// remove all the filtered specifiers
		[newSpecifiers removeObjectsInArray:specifiersToRemove];

		// and assign it to specifiers again
		specifiers = newSpecifiers;
	}

	if (twitterUsernames.count > 0 || twitterUserIDs.count > 0) {
		// Queue up all Twitter usernames/user IDs at once so we can bulk load them for performance.
		[[HBTwitterAPIClient sharedInstance] queueLookupsForUsernames:twitterUsernames userIDs:twitterUserIDs];
	}

	return specifiers;
}

- (UIImage *)_hb_symbolImageFromDictionary:(NSDictionary <NSString *, id> *)params {
	if (@available(iOS 13, *)) {
		return systemSymbolImageForDictionary(params);
	}
	return nil;
}

#pragma mark - Appearance

- (void)_hb_getAppearance {
	[super _hb_getAppearance];
	[self _handleDeprecatedAppearanceMethods];
}

#pragma mark - Navigation controller quirks

- (UINavigationController *)realNavigationController {
	return [super _hb_realNavigationController];
}

#pragma mark - Table View

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath {
	// fixes weird iOS 7 glitch, a little neater than before, and ideally preventing
	// crashes on iPads and older devices.
	[super tableView:tableView didSelectRowAtIndexPath:indexPath];
	[tableView deselectRowAtIndexPath:indexPath animated:YES];
}

@end
