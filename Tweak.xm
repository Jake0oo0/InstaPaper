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
     if ( !error )
     {
      UIImage *image = [[UIImage alloc] initWithData:data];
      completionBlock(YES,image);
    } else{
      completionBlock(NO,nil);
    }
  }];
}
@end

static void setWallpaper(UIImage *image, PLWallpaperMode mode) {
  PLStaticWallpaperImageViewController *controller = [[%c(PLStaticWallpaperImageViewController) alloc] initWithUIImage:image];

  int mode = MSHookIvar<NSUInteger>(controller, "_wallpaperMode");
  mode = PLWallpaperModeBoth;

  controller.saveWallpaperData = YES;
  [controller _savePhoto];
}

static void reloadType(PLWallpaperMode mode) {
  NSString *feedUsername;
  if (mode == PLWallpaperModeBoth) {
    reloadType(PLWallpaperModeHomeScreen);
    reloadType(PLWallpaperModeLockScreen);
    return;
  } else if (mode == PLWallpaperModeHomeScreen) {

  } else if (mode == PLWallpaperModeLockScreen) {

  }
  NSLog(@"[INSTAPAPER]RELOADING FEED!!");
  NSString *instaString = [NSString stringWithFormat:@"https://www.instagram.com/%@/", feedUsername];
  NSURL *instURL = [NSURL URLWithString:instaString];
  // NSData *htmlData = [NSData dataWithContentsOfURL:instURL];

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

      // NSLog(@"JSON %@", json);
          break;
        }
      }


      NSError *localError = nil;
      NSDictionary *parsedObject = [NSJSONSerialization JSONObjectWithData:[json dataUsingEncoding:NSUTF8StringEncoding] options:0 error:&localError];

  // NSLog(@"JSON DATA %@", parsedObject);
  // NSLog(@"[INSTAPAPER] NODES %@", nodes);

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
          setWallpaper(image);
        }
      }];
      
    } else {
    }
  }];



  // PLStaticWallpaperImageViewController *controller = [[PLStaticWallpaperImageViewController alloc] initWithUIImage:]
}


%group sbHooks

%hook SBLockScreenManager
- (void)_finishUIUnlockFromSource:(int)source withOptions:(id)options {
  %orig;
  NSLog(@"[INSTAPAPER] DEVICE UNLOCKED!!!");
  if (enabled) {
    reloadFeed();
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