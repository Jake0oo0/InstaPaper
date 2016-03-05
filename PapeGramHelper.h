@interface PaperGramHelper : NSObject
+ (void)downloadImageWithURL:(NSURL *)url completionBlock:(void (^)(BOOL succeeded, UIImage *image))completionBlock;
+ (UIImage*)imageWithImage:(UIImage *)image convertToSize:(CGSize)size;
+ (CGPoint) lowerLeftOf:(UIImage *)image;
+ (CGSize) screenSize;
+ (UIImage*) drawCaption:(NSString*)text inImage:(UIImage*)image;
@end