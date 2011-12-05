//
//  DetailViewController.h
//  PhotoDispatch
//
//
//  Copyright (c) 2011 Nathan Eror & Free Time Studios. All rights reserved.
//

#import <UIKit/UIKit.h>

@interface DetailViewController : UIViewController

@property (strong, nonatomic) NSURL *imageUrl;
@property (unsafe_unretained) BOOL shouldUseGCD;

- (id)initWithImageAtURL:(NSURL *)theImageUrl;

@end
