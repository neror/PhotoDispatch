//
//  DetailViewController.m
//  PhotoDispatch
//
//  Copyright (c) 2011 Nathan Eror & Free Time Studios. All rights reserved.
//


#import "DetailViewController.h"
#import "ImageHelpers.h"

@interface DetailViewController ()

@property (nonatomic, strong) IBOutlet UIImageView *imageView;

@end

@implementation DetailViewController

@synthesize imageUrl = _imageUrl;
@synthesize imageView = _imageView;
@synthesize shouldUseGCD = _shouldUseGCD;

- (id)initWithImageAtURL:(NSURL *)theImageUrl {
  self = [super initWithNibName:@"DetailViewController" bundle:nil];
  if (self) {
    self.title = [theImageUrl lastPathComponent];
    _imageUrl = theImageUrl;
    _shouldUseGCD = NO;
  }
  return self;
}

#pragma mark - View lifecycle

- (void)viewWillAppear:(BOOL)animated {
  self.title = [self.imageUrl lastPathComponent];
  UIImage *image;
  if(self.shouldUseGCD) {
    image = [UIImage imageNamed:@"ThumbnailLoadingImage"];
    self.imageView.contentMode = UIViewContentModeCenter;
    dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_HIGH, 0), ^{
      CGImageRef convolvedImage = RandomConvolutionCopyOfImageAtURL((__bridge CFURLRef)self.imageUrl);
      UIImage *uiImage = [UIImage imageWithCGImage:convolvedImage];
      CGImageRelease(convolvedImage);
      dispatch_async(dispatch_get_main_queue(), ^{
        self.imageView.image = uiImage;
        self.imageView.contentMode = UIViewContentModeScaleAspectFit;
      });
    });
  } else {
    CGImageRef convolvedImage = RandomConvolutionCopyOfImageAtURL((__bridge CFURLRef)self.imageUrl);
    image = [UIImage imageWithCGImage:convolvedImage];
    CGImageRelease(convolvedImage);
  }
  self.imageView.image = image;
}

- (BOOL)shouldAutorotateToInterfaceOrientation:(UIInterfaceOrientation)interfaceOrientation {
  return UIInterfaceOrientationIsPortrait(interfaceOrientation);
}

@end
