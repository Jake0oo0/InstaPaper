#import "Headers.h"
#import <Foundation/Foundation.h>
#import <UIKit/UIKit.h>
#import "lib/TFHpple.h"

static NSString *prefsLoc = @"/var/mobile/Library/Preferences/com.jake0oo0.instapaper.plist";

static NSString *lockUsername = @"erwnchow";
static BOOL lockEnabled = YES;
static NSString *homeUsername = @"erwnchow";
static BOOL homeEnabled = YES;
static BOOL enabled = YES;

static NSDictionary* loadPrefs() {
  BOOL exists = [[NSFileManager defaultManager] fileExistsAtPath:prefsLoc];

  if (exists) {
    NSMutableDictionary *prefs = [[NSMutableDictionary alloc] initWithContentsOfFile:prefsLoc];
    if (prefs) {
      enabled = [prefs objectForKey:@"enabled"] ? [[prefs objectForKey:@"enabled"] boolValue] : YES;
      homeEnabled = [prefs objectForKey:@"home_enabled"] ? [[prefs objectForKey:@"home_enabled"] boolValue] : YES;
      lockEnabled = [prefs objectForKey:@"lock_enabled"] ? [[prefs objectForKey:@"lock_enabled"] boolValue] : YES;
      lockUsername = [prefs objectForKey:@"lock_username"] ? [prefs objectForKey:@"lock_username"] : nil;
      homeUsername = [prefs objectForKey:@"home_username"] ? [prefs objectForKey:@"home_username"] : nil;

      return prefs;
    }
  }

  return nil;
}
@interface InstaPaperHelper : NSObject
+ (void)downloadImageWithURL:(NSURL *)url completionBlock:(void (^)(BOOL succeeded, UIImage *image))completionBlock;
@end

@implementation InstaPaperHelper
+ (void)downloadImageWithURL:(NSURL *)url completionBlock:(void (^)(BOOL succeeded, UIImage *image))completionBlock {
  NSMutableURLRequest *request = [NSMutableURLRequest requestWithURL:url];
  [NSURLConnection sendAsynchronousRequest:request
   queue:[NSOperationQueue mainQueue]
   completionHandler:^(NSURLResponse *response, NSData *data, NSError *error) {
    if (!error) {
      UIImage *image = [[UIImage alloc] initWithData:data];
      completionBlock(YES,image);
    } else {
      completionBlock(NO,nil);
    }
  }];
}
@end

static void setWallpaper(UIImage *image, PLWallpaperMode mode) {
  PLStaticWallpaperImageViewController *controller = [[%c(PLStaticWallpaperImageViewController) alloc] initWithUIImage:image];

  controller.saveWallpaperData = YES;
  
  NSLog(@"MODE %d", (int)mode);

  int modeVar = MSHookIvar<NSUInteger>(controller, "_wallpaperMode");
  modeVar = mode;

  [controller _savePhoto];
}

static void reloadType(PLWallpaperMode paperMode) {
  NSString *feedUsername;
  if (paperMode == PLWallpaperModeBoth) {
    if (![lockUsername isEqualToString:homeUsername]) {
      NSLog(@"SETTING BOTH DIFFERETN!!");
      reloadType(PLWallpaperModeHomeScreen);
      reloadType(PLWallpaperModeLockScreen);
      return;
    }
    NSLog(@"SETTING BOTH SAME");
    feedUsername = lockUsername;
  } else if (paperMode == PLWallpaperModeHomeScreen) {
    NSLog(@"SET HOME SCREEN");
    feedUsername = homeUsername;
  } else if (paperMode == PLWallpaperModeLockScreen) {
    NSLog(@"SET LOCK SCREEN");
    feedUsername = lockUsername;
  }

  NSLog(@"USING FEED USERNAME %@", feedUsername);

  if (!feedUsername) return;

  NSString *instaString = [NSString stringWithFormat:@"https://www.instagram.com/%@/", feedUsername];
  NSURL *instURL = [NSURL URLWithString:instaString];

  NSMutableURLRequest *request = [[NSMutableURLRequest alloc] init];
  [request setURL:instURL];
  [NSURLConnection sendAsynchronousRequest:request
   queue:[NSOperationQueue mainQueue]
   completionHandler:^(NSURLResponse *response, NSData *data, NSError *error) {
    if (!error) {
      TFHpple *parser = [TFHpple hppleWithHTMLData:data];

      NSString *query = @"/html/body/script";
      NSArray *nodes = [parser searchWithXPathQuery:query];
      NSString *json;

      for (TFHppleElement *element in nodes) {
        if ([[element content] containsString:@"window._sharedData"]) {
          NSString *content = [element content];
          json = [content stringByReplacingOccurrencesOfString:@"window._sharedData = " withString:@""];
          json = [json substringToIndex:[json length] - 1];
          break;
        }
      }


      NSError *localError = nil;
      NSDictionary *parsedObject = [NSJSONSerialization JSONObjectWithData:[json dataUsingEncoding:NSUTF8StringEncoding] options:0 error:&localError];

      NSDictionary *entry = [parsedObject objectForKey:@"entry_data"];
      NSArray *profile = [entry objectForKey:@"ProfilePage"];
  // NSLog(@"PROFILE %@", profile);
      NSDictionary *user = [[profile objectAtIndex:0] objectForKey:@"user"];
  // NSLog(@"USER %@", user);
      NSDictionary *media = [user objectForKey:@"media"];
  // NSLog(@"MEDIA %@ -- keys %@", media, [user allKeys]);
      NSArray *jsnodes = [media objectForKey:@"nodes"];
  // NSLog(@"NODES %@", jsnodes);

      NSDictionary *latest = [jsnodes objectAtIndex:0];

  // NSLog(@"LATEST %@", latest);

      NSString *picURL = [latest objectForKey:@"display_src"];

      NSLog(@"URL %@", picURL);

      [InstaPaperHelper downloadImageWithURL:[NSURL URLWithString:picURL] completionBlock:^(BOOL succeeded, UIImage *image) {
        if (succeeded) {

          setWallpaper(image, paperMode);
        }
      }];
      
    } else {
    }
  }];

}


%group sbHooks

%hook SBLockScreenManager
- (void)_finishUIUnlockFromSource:(int)source withOptions:(id)options {
  %orig;

  if (enabled && homeEnabled) {
    if (lockEnabled) {
      return reloadType(PLWallpaperModeBoth);
    }
    reloadType(PLWallpaperModeHomeScreen);
  }
}

- (void)lockUIFromSource:(int)source withOptions:(id)options {
  %orig;

  if (enabled && lockEnabled) {
    reloadType(PLWallpaperModeLockScreen);
  }
}
%end

%end

static void handlePrefsChange(CFNotificationCenterRef center, void *observer, CFStringRef name, const void *object, CFDictionaryRef userInfo) {
  loadPrefs();
}

%ctor {

  @autoreleasepool {
    loadPrefs();

    CFNotificationCenterAddObserver(
      CFNotificationCenterGetDarwinNotifyCenter(), 
      NULL,
      &handlePrefsChange,
      (CFStringRef)@"com.jake0oo0.instapaper/prefsChange",
      NULL, 
      CFNotificationSuspensionBehaviorCoalesce);

    %init(sbHooks);
  }
}