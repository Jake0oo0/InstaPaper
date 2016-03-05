#import "Headers.h"
#import <Foundation/Foundation.h>
#import <UIKit/UIKit.h>
#import "lib/TFHpple.h"
#import <libactivator/libactivator.h>
#import "PapeGramHelper.h"
#import "PaperGramChangerListener.h"

static NSString *prefsLoc = @"/User/Library/Preferences/com.jake0oo0.papergram.plist";

static NSString *lockUsername = nil;
static BOOL lockEnabled = YES;
static NSString *homeUsername = nil;
static BOOL embedUsername = YES;
static BOOL homeEnabled = YES;
static BOOL enabled = YES;
static BOOL randomPictures = YES;
static BOOL resizePictures = YES;
static int activationInterval = 5;

static BOOL triggeredByActivator = NO;
static NSDate *lastActivationTime = nil;
UIAlertView *progressHUD;

static NSDictionary* loadPrefs() {
	//HBLogDebug(@"Loading preferences...");
  BOOL exists = [[NSFileManager defaultManager] fileExistsAtPath:prefsLoc];

  if (exists) {
    NSMutableDictionary *prefs = [[NSMutableDictionary alloc] initWithContentsOfFile:prefsLoc];
    if (prefs) {
      enabled = [prefs objectForKey:@"enabled"] ? [[prefs objectForKey:@"enabled"] boolValue] : YES;
      homeEnabled = [prefs objectForKey:@"home_enabled"] ? [[prefs objectForKey:@"home_enabled"] boolValue] : YES;
      lockEnabled = [prefs objectForKey:@"lock_enabled"] ? [[prefs objectForKey:@"lock_enabled"] boolValue] : YES;
      lockUsername = [prefs objectForKey:@"lock_username"] ? [prefs objectForKey:@"lock_username"] : nil;
      homeUsername = [prefs objectForKey:@"home_username"] ? [prefs objectForKey:@"home_username"] : nil;
			embedUsername = [prefs objectForKey:@"embedUsername"] ? [[prefs objectForKey:@"embedUsername"] boolValue] : YES;
      randomPictures = [prefs objectForKey:@"random_pictures"] ? [[prefs objectForKey:@"random_pictures"] boolValue] : YES;
      resizePictures = [prefs objectForKey:@"resize_pictures"] ? [[prefs objectForKey:@"resize_pictures"] boolValue] : YES;

      activationInterval = [prefs objectForKey:@"random_pictures"] ? [[prefs objectForKey:@"random_pictures"] intValue] : 5;

      return prefs;
    }
  }

  return nil;
}

static void setWallpaper(UIImage *image, PLWallpaperMode mode) {
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

  if (!feedUsername) {
    if (progressHUD) {
      [progressHUD setMessage:@"Failed."];
      [progressHUD dismissWithClickedButtonIndex:0 animated:YES];
    };
    triggeredByActivator = NO;
    return;
  }

	//HBLogDebug(@"Feeds = %@", feedUsername);
	//[progressHUD setMessage:@"Loading feed..."];
	/*support multiple accounts, comma separted*/
	NSArray *array = [feedUsername componentsSeparatedByString:@","];
	feedUsername = [array objectAtIndex:( arc4random() % [array count] )];

	//HBLogDebug(@"Selected feed = %@", feedUsername);

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
		[progressHUD setMessage:@"Downloading image..."];
    [PaperGramHelper downloadImageWithURL:[NSURL URLWithString:picURL] completionBlock:^(BOOL succeeded, UIImage *image) {
      if (succeeded && image) {
				/* Put the resizing here instead */
				if (resizePictures) {
					[progressHUD setMessage:@"Resizing..."];
			    CGRect screenBounds = [[UIScreen mainScreen] bounds];
			    CGFloat screenScale = [[UIScreen mainScreen] scale];
			    CGSize screenSize = CGSizeMake(screenBounds.size.width * screenScale, screenBounds.size.height * screenScale);
			    image = [PaperGramHelper imageWithImage:image convertToSize:screenSize];
			  }
				/* add the username */
				if (embedUsername) {
					[progressHUD setMessage:@"Captioning..."];
					NSString * caption = [NSString stringWithFormat:@"@%@", feedUsername];
					image = [PaperGramHelper drawCaption:caption inImage:image];
				}
				[progressHUD setMessage:@"Setting wallpaper(s)..."];
        setWallpaper(image, paperMode);

				if (progressHUD) {
					[progressHUD setMessage:@"Done."];
					[progressHUD dismissWithClickedButtonIndex:0 animated:YES];
				};
				triggeredByActivator = NO;
      } else {
				if (progressHUD) {
					[progressHUD setMessage:@"Failed."];
					[progressHUD dismissWithClickedButtonIndex:0 animated:YES];
				};
				triggeredByActivator = NO;
			}


    }];

  }];

}

static void triggerWallpaperChange() {
	//HBLogDebug(@"triggerWallpaperChange called.");
	//if (triggeredByActivator)	HBLogDebug(@"Triggered by activator.");

	if (enabled) {

		int effActivationInterval = activationInterval;
		if (activationInterval < 1) {
			//HBLogDebug(@"Activation interval is Never.")
			effActivationInterval = 99999;
		}

		//HBLogDebug(@"effActivationInterval = %d", effActivationInterval);

		if (!lastActivationTime) {
			lastActivationTime = [NSDate date];
			if (!triggeredByActivator)	return;
		}
		if (!triggeredByActivator) {
			//HBLogDebug(@"Performing lastActivationTime check");
			// perform lastActivationTime check. otherwise, skip this and change the wallpaper
			if (!lastActivationTime || [[NSDate date] timeIntervalSinceDate:lastActivationTime] < (effActivationInterval * 60)) return;
		}

		//HBLogDebug(@"Time to change wallpapers.")

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

%group sbHooks

%hook SBLockScreenManager
- (void)_finishUIUnlockFromSource:(int)source withOptions:(id)options {
  %orig;

	triggerWallpaperChange();
}

%end

%end

@implementation PaperGramChangerListener

- (void)activator:(LAActivator *)activator receiveEvent:(LAEvent *)event {
	//HBLogDebug(@"**********************************");
	//HBLogDebug(@"*   Activator Trigger Received   *");
	//HBLogDebug(@"**********************************");

	if (triggeredByActivator) {
		//HBLogDebug(@"Wallpaper change aborted. Still running previous change.");
		[event setHandled:YES];
		return;
	}
	loadPrefs();
	//HBLogDebug(@"Marking activator flag.");
	triggeredByActivator = YES;

	//HBLogDebug(@"Show progressHUD");
	progressHUD = [[UIAlertView alloc] initWithTitle:@"PaperGram" message:@"Running PaperGram..." delegate:self cancelButtonTitle:nil otherButtonTitles:nil];
	[progressHUD show];

	//[ProgressHUD dismiss];
	//[ProgressHUD show:@"Updating wallpaper..."];

	//HBLogDebug(@"Call triggerWallpaperChange");
	triggerWallpaperChange();
 	// Activate your plugin
 	[event setHandled:YES]; // To prevent the default OS implementation
}

- (void)activator:(LAActivator *)activator abortEvent:(LAEvent *)event {
	// Dismiss your plugin
}

+ (void)load {
	if ([[[NSBundle mainBundle] bundleIdentifier] isEqualToString:@"com.apple.springboard"])
  	[[%c(LAActivator) sharedInstance] registerListener:[self new] forName:@"com.jake0oo0.papergramchanger"];
	/*
	if ([LASharedActivator isRunningInsideSpringBoard]) {
		[LASharedActivator registerListener:[self new] forName:@"com.jake0oo0.papergramchanger"];
	}
	*/
}

@end

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
      (CFStringRef)@"com.jake0oo0.papergram/prefsChange",
      NULL,
      CFNotificationSuspensionBehaviorCoalesce);

    %init(sbHooks);
  }
}
