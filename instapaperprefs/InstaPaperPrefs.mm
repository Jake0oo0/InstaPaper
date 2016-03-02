#import <Preferences/Preferences.h>
#import <SettingsKit/SKListControllerProtocol.h>
#import <SettingsKit/SKTintedListController.h>
#import <SettingsKit/SKPersonCell.h>
#import <SettingsKit/SKSharedHelper.h>

#define valuesPath @"/User/Library/Preferences/com.jake0oo0.instapaper.plist"

@interface DeveloperCell : SKPersonCell
@end

@interface DesignerCell : SKPersonCell
@end

@interface DevelopersListCell : SKTintedListController <SKListControllerProtocol>
@end


@interface InstaPaperPrefsListController: SKTintedListController<SKListControllerProtocol>
@end

@implementation InstaPaperPrefsListController


- (UIColor*) tintColor { return [UIColor colorWithRed:0.071 green:0.337 blue:0.533 alpha:1]; }
-(BOOL)tintNavigationTitleText { 
  return YES; 
}

-(NSString *)shareMessage {
    return @"I'm using #InstaPaper by @itsjake88 to set my iOS background to Instagram pics. Check it out!";
}

-(NSString *)headerText { 
  return @"InstaPaper"; 
}

-(NSString *)headerSubText {
  return @"Instagram Wallpapers";
}

-(NSString *)customTitle { 
  return @"InstaPaper"; 
}

-(NSArray*) customSpecifiers
{
    return @[
     @{
         @"cell": @"PSGroupCell",
         @"label": @"InstaPaper Settings"
     },
     @{
         @"cell": @"PSSwitchCell",
         @"default": @YES,
         @"defaults": @"com.jake0oo0.instapaperprefs",
         @"key": @"enabled",
         @"label": @"Enabled",
         @"PostNotification": @"com.jake0oo0.instapaper/prefsChange",
         @"cellClass": @"SKTintedSwitchCell"
     },

     @{
         @"cell": @"PSGroupCell",
         @"label": @"Lockscreen"
     },
     @{
         @"cell": @"PSSwitchCell",
         @"default": @YES,
         @"defaults": @"com.jake0oo0.instapaperprefs",
         @"key": @"lock_enabled",
         @"label": @"Enabled",
         @"PostNotification": @"com.jake0oo0.instapaper/prefsChange",
         @"cellClass": @"SKTintedSwitchCell"
     },
     @{
      @"cell": @"PSEditTextCell",
      @"default": @"",
      @"defaults": @"com.jake0oo0.instapaperprefs",
      @"key": @"lock_username",
      @"label": @"Feed Username",
      @"PostNotification": @"com.jake0oo0.instapaper/prefsChange"
  },

  @{
     @"cell": @"PSGroupCell",
     @"label": @"Homescreen"
 },
 @{
     @"cell": @"PSSwitchCell",
     @"default": @YES,
     @"defaults": @"com.jake0oo0.instapaperprefs",
     @"key": @"home_enabled",
     @"label": @"Enabled",
     @"PostNotification": @"com.jake0oo0.instapaper/prefsChange",
     @"cellClass": @"SKTintedSwitchCell"
 },
 @{
  @"cell": @"PSEditTextCell",
  @"default": @"",
  @"defaults": @"com.jake0oo0.instapaperprefs",
  @"key": @"home_username",
  @"label": @"Feed Username",
  @"PostNotification": @"com.jake0oo0.instapaper/prefsChange"
},
@{
  @"cell": @"PSGroupCell",
  @"label": @"Developers"
},
@{
  @"cell": @"PSLinkCell",
  @"cellClass": @"SKTintedCell",
  @"detail": @"DevelopersListCell",
  @"label": @"Developers"
},
@{
     @"cell": @"PSGroupCell",
     @"label": @"Pictures"
 },
  @{
     @"cell": @"PSSwitchCell",
     @"default": @YES,
     @"defaults": @"com.jake0oo0.instapaperprefs",
     @"key": @"random_pictures",
     @"label": @"Random Pictures",
     @"PostNotification": @"com.jake0oo0.instapaper/prefsChange",
     @"cellClass": @"SKTintedSwitchCell"
 },
 @{
     @"cell": @"PSSwitchCell",
     @"default": @YES,
     @"defaults": @"com.jake0oo0.instapaperprefs",
     @"key": @"resize_pictures",
     @"label": @"Resize Pictures (experimental)",
     @"PostNotification": @"com.jake0oo0.instapaper/prefsChange",
     @"cellClass": @"SKTintedSwitchCell"
 },
 @{
      @"cell": @"PSLinkListCell",
      @"default": @5,
      @"defaults": @"com.jake0oo0.instapaperprefs",
      @"key": @"activation_interval",
      @"label": @"Activate Every...",
      @"PostNotification": @"com.jake0oo0.instapaper/prefsChange",
      @"validTitles": @[
        @"5 Minutes",
        @"10 Minutes",
        @"Half Hour",
        @"Hour",
        @"90 Minutes",
        @"Two Hours",
        @"3 Hours"
      ],
      @"validValues": @[
        @5,
        @10,
        @30,
        @60,
        @90,
        @120,
        @180
      ],
      @"detail": @"PSListItemsController"
    },
];
}

// http://iphonedevwiki.net/index.php/PreferenceBundles
-(id) readPreferenceValue:(PSSpecifier *)specifier {
  NSDictionary *settings = [NSDictionary dictionaryWithContentsOfFile:valuesPath];
  if (!settings[specifier.properties[@"key"]]) {
    return specifier.properties[@"default"];
  }
  return settings[specifier.properties[@"key"]];
}
 
-(void) setPreferenceValue:(id)value specifier:(PSSpecifier *)specifier {
  NSMutableDictionary *defaults = [NSMutableDictionary dictionary];
  [defaults addEntriesFromDictionary:[NSDictionary dictionaryWithContentsOfFile:valuesPath]];
  [defaults setObject:value forKey:specifier.properties[@"key"]];
  [defaults writeToFile:valuesPath atomically:NO];
  CFStringRef toPost = (__bridge CFStringRef)specifier.properties[@"PostNotification"];
  if (toPost) CFNotificationCenterPostNotification(CFNotificationCenterGetDarwinNotifyCenter(), toPost, NULL, NULL, YES);
}
// end
@end


@implementation DeveloperCell
-(NSString *)personDescription { return @"Lead Developer"; }
-(NSString *)name { return @"Jake0oo0"; }
-(NSString *)twitterHandle { return @"itsjake88"; }
-(NSString *)imageName { return @"Jake@2x.png"; }
@end

@implementation DesignerCell
-(NSString *)personDescription { return @"Lead Designer"; }
-(NSString *)name { return @"AOkhtenberg"; }
-(NSString *)twitterHandle { return @"AOkhtenberg"; }
-(NSString *)imageName { return @"AOkhtenberg@2x.png"; }
@end

@implementation DevelopersListCell
-(BOOL)showHeartImage {
  return NO;
}

-(void)openJakeTwitter {
  [SKSharedHelper openTwitter:@"itsjake88"];
}

-(void)openAOkTwitter {
  [SKSharedHelper openTwitter:@"AOkhtenberg"];
}

-(NSArray *)customSpecifiers {
  return @[
    @{
      @"cell": @"PSLinkCell",
      @"cellClass": @"DeveloperCell",
      @"height": @100,
      @"action": @"openJakeTwitter"
  },
  @{
      @"cell": @"PSLinkCell",
      @"cellClass": @"DesignerCell",
      @"height": @100,
      @"action": @"openAOkTwitter"
  }
  ];
}
@end