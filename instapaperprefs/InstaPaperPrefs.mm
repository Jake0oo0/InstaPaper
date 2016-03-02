#import <Preferences/Preferences.h>
#import <SettingsKit/SKListControllerProtocol.h>
#import <SettingsKit/SKTintedListController.h>
#import <SettingsKit/SKPersonCell.h>
#import <SettingsKit/SKSharedHelper.h>

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
         @"key": @"lockscreen_enabled",
         @"label": @"Enabled",
         @"PostNotification": @"com.jake0oo0.instapaper/prefsChange",
         @"cellClass": @"SKTintedSwitchCell"
     },
     @{
      @"cell": @"PSEditTextCell",
      @"default": @"",
      @"defaults": @"com.jake0oo0.instapaperprefs",
      @"key": @"lockscren_feed",
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
     @"key": @"homescreen_enabled",
     @"label": @"Enabled",
     @"PostNotification": @"com.jake0oo0.instapaper/prefsChange",
     @"cellClass": @"SKTintedSwitchCell"
 },
 @{
  @"cell": @"PSEditTextCell",
  @"default": @"",
  @"defaults": @"com.jake0oo0.instapaperprefs",
  @"key": @"homescreen_feed",
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
}
];
}
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