//
//  PhotoGridTableCell.m
//  PhotoDispatch
//
//  Copyright (c) 2011 Nathan Eror & Free Time Studios. All rights reserved.
//

#import "PhotoGridTableCell.h"
#import "FTUtils+UIGestureRecognizer.h"
#import "ImageHelpers.h"

#define USE_VIMAGE 1
#define USE_GCD 1
#define USE_NSCACHE 1

const NSUInteger kThumbnailsPerRow = 3;
const int kThumbnailSize = 100;
typedef void (^ImageLoadCompletionBlock)(UIImage *loadedImage);

@interface PhotoGridTableCell()

@property (strong) NSMutableArray *imageViews;

- (void)asyncLoadThumbnailImageAtURL:(NSURL *)url completion:(ImageLoadCompletionBlock)completion;

@end

@implementation PhotoGridTableCell

@synthesize photoUrls = _photoUrls;
@synthesize delegate = _delegate;
@synthesize imageViews = _imageViews;
@synthesize thumbnailCache = _thumbnailCache;
@synthesize shouldUseGCD = _shouldUseGCD;
@synthesize shouldConvolveImages = _shouldConvolveImages;
@synthesize imageProcessingQueue = _imageProcessingQueue;
@synthesize imageProcessingSemaphore = _imageProcessingSemaphore;

- (id)initWithStyle:(UITableViewCellStyle)style reuseIdentifier:(NSString *)reuseIdentifier {
  self = [super initWithStyle:style reuseIdentifier:reuseIdentifier];
  if (self) {
    _imageViews = [[NSMutableArray alloc] init];
    _shouldUseGCD = NO;
    _shouldConvolveImages = NO;
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(toggleGCD:) name:kShouldUseGCDNotification object:nil];
  }
  return self;
}

- (void)dealloc {
  [[NSNotificationCenter defaultCenter] removeObserver:self];
}

- (void)toggleGCD:(NSNotification *)notification {
  self.shouldUseGCD = [[notification object] boolValue];
}

- (UIImage *)thumbnailImageAtURL:(NSURL *)url {
  UIImage *image = [self.thumbnailCache objectForKey:[url absoluteString]];
  if(!image) {
    if(self.shouldConvolveImages) {
      CGImageRef thumbnailImage = CGImageCreateThumbnailFromImageAtURL((__bridge CFURLRef)url, kThumbnailSize);
      CGImageRef convolvedThumbnail = RandomConvolutionCopyOfImage(thumbnailImage);
      image = [UIImage imageWithCGImage:convolvedThumbnail];
      CGImageRelease(convolvedThumbnail);
      CGImageRelease(thumbnailImage);
    } else {
      CGImageRef thumbnailImage = CGImageCreateThumbnailFromImageAtURL((__bridge CFURLRef)url, kThumbnailSize);
      image = [UIImage imageWithCGImage:thumbnailImage];
      CGImageRelease(thumbnailImage);
    }
    [self.thumbnailCache setObject:image forKey:[url absoluteString]];
  }
  return image;
}


- (void)asyncLoadThumbnailImageAtURL:(NSURL *)url completion:(ImageLoadCompletionBlock)completion {
  __weak id weakSelf = self;
  dispatch_async(self.imageProcessingQueue, ^{
    if([weakSelf imageProcessingSemaphore]) {
      dispatch_semaphore_wait([weakSelf imageProcessingSemaphore], DISPATCH_TIME_FOREVER);
    }
    UIImage *image = [weakSelf thumbnailImageAtURL:url];
    dispatch_async(dispatch_get_main_queue(), ^{
      completion(image);
    });
    if([weakSelf imageProcessingSemaphore]) {
      dispatch_semaphore_signal([weakSelf imageProcessingSemaphore]);
    }
  });
}


/*
- (void)asyncLoadThumbnailImageAtURL:(NSURL *)url completion:(ImageLoadCompletionBlock)completion {
  dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_HIGH, 0), ^{
    UIImage *image = [self thumbnailImageAtURL:url];
    dispatch_async(dispatch_get_main_queue(), ^{
      completion(image);
    });
  });
}
*/

- (void)layoutSubviews {
  CGFloat cellWidth = 320.f;
  CGFloat spacing = (cellWidth - kThumbnailSize * kThumbnailsPerRow) / (kThumbnailsPerRow + 1);
  self.selectionStyle = UITableViewCellSelectionStyleNone;

  [self.photoUrls enumerateObjectsUsingBlock:^(NSURL *photoUrl, NSUInteger idx, BOOL *stop) {
    UIImageView *thumbnailView;
    if([self.imageViews count] > idx) {
      thumbnailView = [self.imageViews objectAtIndex:idx];
    } else {
      thumbnailView = [[UIImageView alloc] initWithFrame:CGRectMake(0.f, 0.f, kThumbnailSize, kThumbnailSize)];
      thumbnailView.userInteractionEnabled = YES;
      [self.imageViews insertObject:thumbnailView atIndex:idx];
    }
    
    for (UIGestureRecognizer *recognizer in thumbnailView.gestureRecognizers) {
      [thumbnailView removeGestureRecognizer:recognizer];
    }
    
    [thumbnailView addGestureRecognizer:[UITapGestureRecognizer recognizerWithActionBlock:^(UITapGestureRecognizer *recognizer) {
      if(self.delegate && [self.delegate respondsToSelector:@selector(photoGridCell:didSelectPhotoAtUrl:)]) {
        [self.delegate photoGridCell:self didSelectPhotoAtUrl:photoUrl];
      }
    }]];
    
    if(self.shouldUseGCD) {
      __block PhotoGridTableCell *weakSelf = self;
      thumbnailView.image = [UIImage imageNamed:@"ThumbnailLoadingImage"];
      [self asyncLoadThumbnailImageAtURL:photoUrl completion:^(UIImage *loadedImage) {
        if([weakSelf.photoUrls containsObject:photoUrl]) {
          thumbnailView.image = loadedImage;
        }
      }];
    } else {
      thumbnailView.image = [self thumbnailImageAtURL:photoUrl];
    }
    
    CGRect thumbnailFrame = CGRectMake(spacing + (kThumbnailSize * idx) + (spacing * idx), 
                                       (self.bounds.size.height - kThumbnailSize) / 2.f, 
                                       kThumbnailSize, 
                                       kThumbnailSize);
    thumbnailView.frame = thumbnailFrame;
    thumbnailView.contentMode = UIViewContentModeScaleToFill;
    if(thumbnailView.superview != self) {
      [thumbnailView removeFromSuperview];
      [self addSubview:thumbnailView];
    }
  }];
}

- (void)setSelected:(BOOL)selected animated:(BOOL)animated {}

@end
