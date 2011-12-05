//
//  MasterViewController.h
//  PhotoDispatch
//
//  Copyright (c) 2011 Nathan Eror & Free Time Studios. All rights reserved.
//


#import <UIKit/UIKit.h>
#import "PhotoGridTableCell.h"

@class DetailViewController;

@interface MasterViewController : UITableViewController <PhotoGridTableCellDelegate>

@property (strong, nonatomic) DetailViewController *detailViewController;

@end
