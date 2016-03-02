#import "Headers.h"
#import <Foundation/Foundation.h>
#import <UIKit/UIKit.h>
#import "lib/TFHpple.h"

static NSString *prefsLoc = @"/User/Library/Preferences/com.jake0oo0.instapaper.plist";

static NSString *lockUsername = nil;
static BOOL lockEnabled = YES;
static NSString *homeUsername = nil;
static BOOL homeEnabled = YES;
static BOOL enabled = YES;
static BOOL randomPictures = YES;
static BOOL resizePictures = YES;
static int activationInterval = 5;

static NSDate *lastActivationTime = nil;

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

      randomPictures = [prefs objectForKey:@"random_pictures"] ? [[prefs objectForKey:@"random_pictures"] boolValue] : YES;
      resizePictures = [prefs objectForKey:@"resize_pictures"] ? [[prefs objectForKey:@"resize_pictures"] boolValue] : YES;

      activationInterval = [prefs objectForKey:@"random_pictures"] ? [[prefs objectForKey:@"random_pictures"] intValue] : 5;

      return prefs;
    }
  }

  return nil;
}

@interface InstaPaperHelper : NSObject
+ (void)downloadImageWithURL:(NSURL *)url completionBlock:(void (^)(BOOL succeeded, UIImage *image))completionBlock;
+ (UIImage *)imageWithImage:(UIImage *)image convertToSize:(CGSize)size;
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
+ (UIImage *)imageWithImage:(UIImage *)image convertToSize:(CGSize)size {
  UIGraphicsBeginImageContext(size);
  [image drawInRect:CGRectMake(0, 0, size.width, size.height)];
  UIImage *destImage = UIGraphicsGetImageFromCurrentImageContext();    
  UIGraphicsEndImageContext();
  return destImage;
}
@end

static void setWallpaper(UIImage *image, PLWallpaperMode mode) {
  if (resizePictures) {
    CGRect screenBounds = [[UIScreen mainScreen] bounds];
    CGFloat screenScale = [[UIScreen mainScreen] scale];
    CGSize screenSize = CGSizeMake(screenBounds.size.width * screenScale, screenBounds.size.height * screenScale);
    image = [InstaPaperHelper imageWithImage:image convertToSize:screenSize];
  }
  PLStaticWallpaperImageViewController *controller = [[%c(PLStaticWallpaperImageViewController) alloc] initWithUIImage:image];

  controller.saveWallpaperData = YES;
  
  MSHookIvar<PLWallpaperMode>(controller, "_wallpaperMode") = mode;

  [controller _savePhoto];
}

static void reloadType(PLWallpaperMode paperMode) {
  NSString *feedUsername;
  if (paperMode == PLWallpaperModeBoth) {
    if (![lockUsername isEqualToString:homeUsername]) {
      reloadType(PLWallpaperModeHomeScreen);
      reloadType(PLWallpaperModeLockScreen);
      return;
    }
    feedUsername = lockUsername;
  } else if (paperMode == PLWallpaperModeHomeScreen) {
    feedUsername = homeUsername;
  } else if (paperMode == PLWallpaperModeLockScreen) {
    feedUsername = lockUsername;
  }

  if (!feedUsername) return;

  NSString *instaString = [NSString stringWithFormat:@"https://www.instagram.com/%@/", feedUsername];
  NSURL *instaUrl = [NSURL URLWithString:instaString];

  NSMutableURLRequest *request = [[NSMutableURLRequest alloc] init];
  [request setURL:instaUrl];
  [NSURLConnection sendAsynchronousRequest:request
   queue:[NSOperationQueue mainQueue]
   completionHandler:^(NSURLResponse *response, NSData *data, NSError *error) {
    if (error) return;
    NSHTTPURLResponse* httpResponse = (NSHTTPURLResponse*)response;
    int statusCode = [httpResponse statusCode];
    if (statusCode == 404 || statusCode == 500) return;
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

    if (!json) return;


    NSError *localError = nil;
    NSDictionary *parsedObject = [NSJSONSerialization JSONObjectWithData:[json dataUsingEncoding:NSUTF8StringEncoding] options:0 error:&localError];

    if (localError || !parsedObject) return;
    NSDictionary *entry = [parsedObject objectForKey:@"entry_data"];
    if (!entry) return;
    NSArray *profile = [entry objectForKey:@"ProfilePage"];
    if (!profile || profile.count == 0) return;
    NSDictionary *user = [[profile objectAtIndex:0] objectForKey:@"user"];
    if (!user) return;
    NSDictionary *media = [user objectForKey:@"media"];
    if (!media) return;
    NSArray *jsnodes = [media objectForKey:@"nodes"];

    if (!jsnodes || [jsnodes count] == 0) return;

    NSDictionary *content;
    int didTest = 0;

    while (!content) {
      if (randomPictures) {
        NSDictionary *testing = jsnodes[arc4random_uniform([jsnodes count])];
        if ([testing objectForKey:@"is_video"] && [[testing objectForKey:@"is_video"] boolValue]) {
          didTest += 1;
          continue;
        }
        content = testing;
      } else {
        NSDictionary *testing = jsnodes[didTest];
        if ([testing objectForKey:@"is_video"] && [[testing objectForKey:@"is_video"] boolValue]) {
          didTest += 1;
          continue;
        } else {
          content = [jsnodes objectAtIndex:didTest];
        }
      }

      if (didTest == [jsnodes count]) break;
    }

    if (!content) return;


    NSString *picURL = [content objectForKey:@"display_src"];
    if (!picURL) return;

    // NSLog(@"URL %@", picURL);

    [InstaPaperHelper downloadImageWithURL:[NSURL URLWithString:picURL] completionBlock:^(BOOL succeeded, UIImage *image) {
      if (succeeded && image) {
        setWallpaper(image, paperMode);
      }
    }];

  }];

}


%group sbHooks

%hook SBLockScreenManager
- (void)_finishUIUnlockFromSource:(int)source withOptions:(id)options {
  %orig;


  if (enabled) {
    if (!lastActivationTime) {
      lastActivationTime = [NSDate date];
      return;
    }
    if (!lastActivationTime || [[NSDate date] timeIntervalSinceDate:lastActivationTime] < (activationInterval * 60)) return;
    lastActivationTime = [NSDate date];
    if (homeEnabled && lockEnabled) {
      reloadType(PLWallpaperModeBoth);
    } else if (homeEnabled) {
      reloadType(PLWallpaperModeHomeScreen);
    } else if (lockEnabled) {
      reloadType(PLWallpaperModeLockScreen);
    }
  }
}

// - (void)lockUIFromSource:(int)source withOptions:(id)options {
//   %orig;

//   if (enabled && source == 1 && homeEnabled) {
//     if (lastActivationTime && [[NSDate date] timeIntervalSinceDate:lastActivationTime] < (activationInterval * 60)) return;
//     if (lockEnabled) {
//       return reloadType(PLWallpaperModeBoth);
//     }
//     reloadType(PLWallpaperModeLockScreen);
//   }
// }
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