#import <Foundation/Foundation.h>
#import <UIKit/UIKit.h>
#import <substrate.h>

typedef NS_ENUM(NSUInteger, PLWallpaperMode) {
  PLWallpaperModeBoth,
  PLWallpaperModeHomeScreen,
  PLWallpaperModeLockScreen
};

@interface PLWallpaperImageViewController : NSObject {
  int _wallpaperMode;
}
@property (nonatomic) BOOL saveWallpaperData;

- (void)_savePhoto;
@end

@interface PLStaticWallpaperImageViewController : PLWallpaperImageViewController
- (id)initWithUIImage:(id)arg1;
@end

@interface SBLockScreenManager
- (void)_finishUIUnlockFromSource:(int)source withOptions:(id)options;
- (void)lockUIFromSource:(int)source withOptions:(id)options;
@end