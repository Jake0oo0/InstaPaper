#import "PapeGramHelper.h"

@implementation PaperGramHelper
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
+(CGSize) screenSize {
  CGRect screenBounds = [[UIScreen mainScreen] bounds];
  CGFloat screenScale = [[UIScreen mainScreen] scale];
  CGSize screenSize = CGSizeMake(screenBounds.size.width * screenScale, screenBounds.size.height * screenScale);
  //HBLogDebug(@"screenSize = %f,%f",screenSize.width, screenSize.height);
  return screenSize;
}
+(CGPoint) lowerLeftOf:(UIImage *)image {
  CGSize screenSize = [self screenSize];
  CGPoint lowerLeft = CGPointMake(0,0);

  if (image.size.width > screenSize.width) {
    lowerLeft.x = image.size.width/2-screenSize.width/2;
  } else {
    lowerLeft.x = 0;
  }

  if (image.size.height > screenSize.height) {
    lowerLeft.y = image.size.height-(image.size.height-screenSize.height)/2;
  } else {
    lowerLeft.y = image.size.height;
  }
  //HBLogDebug(@"lowerLeft = %f,%f", lowerLeft.x, lowerLeft.y)
  return lowerLeft;

}

+(UIImage*) drawCaption:(NSString*)text inImage:(UIImage*)image
{
    //HBLogDebug(@"imagesize = %f,%f", image.size.width, image.size.height);
    CGSize screenSize = [self screenSize];

    UIFont *font = [UIFont boldSystemFontOfSize:12];
    NSMutableParagraphStyle *style = [[NSParagraphStyle defaultParagraphStyle] mutableCopy];
    style.alignment = NSTextAlignmentCenter;

    NSShadow *shadow = [[NSShadow alloc] init];
    shadow.shadowColor = [UIColor colorWithRed:((float)255) green:((float) 255) blue:((float) 0/255) alpha:0.7f];
    shadow.shadowBlurRadius = 5;
    //shadow.shadowOpacity = 0.3;
    shadow.shadowOffset = CGSizeMake(0.0, 0.0);

    //NSDictionary *attribute = [NSDictionary dictionaryWithObjectsAndKeys:font, NSFontAttributeName, nil];
    //UIColor* fontColor = [UIColor colorWithRed:((float)152/255) green:((float) 193/255) blue:((float) 193/255) alpha:1.0f];
    //UIColor* fontColor = [UIColor colorWithRed:0.20 green:0.59 blue:0.37 alpha:1.0];
    UIColor* fontColor = [UIColor blackColor];

    NSDictionary *attribute = @{ NSFontAttributeName: font,
                  NSParagraphStyleAttributeName:style,
                  NSShadowAttributeName:shadow,
                  NSForegroundColorAttributeName:fontColor};

    UIGraphicsBeginImageContext(image.size);

    [image drawInRect:CGRectMake(0,0,image.size.width,image.size.height)];
    //CGRect rect = CGRectMake(point.x, point.y, image.size.width, image.size.height);

    CGPoint lowerLeft = [self lowerLeftOf:image];

    //CGRect rect = CGRectMake(point.x, point.y, screenSize.width, screenSize.height);
    //CGRect rect = CGRectMake(lowerLeft.x, lowerLeft.y-(font.lineHeight*2), screenSize.width, screenSize.height);
    CGRect rect = CGRectMake(
        lowerLeft.x,
        lowerLeft.y-(font.lineHeight*1.5),
        (screenSize.width>image.size.width ? image.size.width : screenSize.width),
        (font.lineHeight*1.5)
    );
    [[UIColor whiteColor] set];
    [text drawInRect:CGRectIntegral(rect) withAttributes:attribute];
    UIImage *newImage = UIGraphicsGetImageFromCurrentImageContext();
    UIGraphicsEndImageContext();

    return newImage;
}
@end