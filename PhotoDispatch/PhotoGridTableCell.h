//
//  PhotoGridTableCell.h
//  PhotoDispatch
//
//  Copyright (c) 2011 Nathan Eror & Free Time Studios. All rights reserved.
//

#import <UIKit/UIKit.h>

@class PhotoGridTableCell;

const NSUInteger kThumbnailsPerRow;
const int kThumbnailSize;
static NSString * const kShouldUseGCDNotification = @"pd_UseGCDNotification";

@protocol PhotoGridTableCellDelegate <NSObject>

- (void)photoGridCell:(PhotoGridTableCell *)cell didSelectPhotoAtUrl:(NSURL *)photoUrl;

@end

@interface PhotoGridTableCell : UITableViewCell

@property (strong) NSArray *photoUrls;
@property (weak) NSCache *thumbnailCache;
@property (weak) id<PhotoGridTableCellDelegate> delegate;
@property (unsafe_unretained) BOOL shouldUseGCD;
@property (unsafe_unretained) BOOL shouldConvolveImages;
@property (unsafe_unretained) dispatch_queue_t imageProcessingQueue;
@property (unsafe_unretained) dispatch_semaphore_t imageProcessingSemaphore;

@end
