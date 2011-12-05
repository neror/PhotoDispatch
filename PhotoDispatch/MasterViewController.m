//
//  MasterViewController.m
//  PhotoDispatch
//
//  Copyright (c) 2011 Nathan Eror & Free Time Studios. All rights reserved.
//

#import "MasterViewController.h"
#import "DetailViewController.h"

@interface MasterViewController() {
  dispatch_queue_t _imageProcessingQueue;
  dispatch_semaphore_t _imageProcessingSemaphore;
}

@property (strong) NSArray *imageUrls;
@property (strong) NSCache *thumbnailCache;
@property (unsafe_unretained) BOOL shouldUseGCD;
@property (unsafe_unretained) BOOL shouldConvolveImages;

@end

@implementation MasterViewController

@synthesize detailViewController = _detailViewController;
@synthesize imageUrls = _imageUrls;
@synthesize thumbnailCache = _thumbnailCache;
@synthesize shouldUseGCD = _shouldUseGCD;
@synthesize shouldConvolveImages = _shouldConvolveImages;

- (id)initWithNibName:(NSString *)nibNameOrNil bundle:(NSBundle *)nibBundleOrNil
{
    self = [super initWithNibName:nibNameOrNil bundle:nibBundleOrNil];
    if (self) {
      self.title = NSLocalizedString(@"Photos", @"Photos");
      NSDirectoryEnumerator *directory = [[NSFileManager defaultManager] enumeratorAtURL:[[NSBundle mainBundle] bundleURL]
                                                              includingPropertiesForKeys:[NSArray arrayWithObject:NSURLNameKey]
                                                                                 options:NSDirectoryEnumerationSkipsSubdirectoryDescendants
                                                                            errorHandler:nil];
      NSMutableArray *urls = [NSMutableArray array];
      for(NSURL *url in directory) {
        NSString *fileName;
        [url getResourceValue:&fileName forKey:NSURLNameKey error:NULL];
        if([[fileName pathExtension] isEqualToString:@"jpg"]) {
          [urls addObject:url];
        }
      }
      self.imageUrls = urls;
      _thumbnailCache = [[NSCache alloc] init];
      _shouldUseGCD = NO;
      _shouldConvolveImages = NO;
      _imageProcessingSemaphore = nil;//dispatch_semaphore_create(4);
      _imageProcessingQueue = dispatch_queue_create("com.freetimestudios.ImageProcessingQueue", DISPATCH_QUEUE_CONCURRENT);
      dispatch_set_target_queue(_imageProcessingQueue, dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_HIGH, 0));
    }
    return self;
}

- (void)dealloc {
  dispatch_release(_imageProcessingQueue);
  dispatch_release(_imageProcessingSemaphore);
}

#pragma mark - View lifecycle

- (void)viewDidLoad
{
  [super viewDidLoad];
  self.navigationItem.rightBarButtonItem = 
    [[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemRefresh target:self action:@selector(reloadImages)]; 
  self.navigationItem.leftBarButtonItem = 
    [[UIBarButtonItem alloc] initWithTitle:@"GCD OFF" style:UIBarButtonItemStyleBordered target:self action:@selector(toggleGCD)];
}

- (void)viewDidUnload {
  [super viewDidUnload];
}

- (void)reloadImages {
  [self.thumbnailCache removeAllObjects];
  self.shouldConvolveImages = !self.shouldConvolveImages;
  [self.tableView reloadData];
}

- (void)toggleGCD {
  self.shouldUseGCD = !self.shouldUseGCD;
  self.navigationItem.leftBarButtonItem.title = self.shouldUseGCD ? @"GCD ON" : @"GCD OFF";
  [[NSNotificationCenter defaultCenter] postNotificationName:kShouldUseGCDNotification object:[NSNumber numberWithBool:self.shouldUseGCD]];
}

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView {
  return 1;
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
  return [self.imageUrls count] / kThumbnailsPerRow;
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
  static NSString *CellIdentifier = @"PhotoGridCell";
  
  PhotoGridTableCell *cell = [tableView dequeueReusableCellWithIdentifier:CellIdentifier];
  if (cell == nil) {
    cell = [[PhotoGridTableCell alloc] initWithStyle:UITableViewCellStyleDefault reuseIdentifier:CellIdentifier];
    cell.accessoryType = UITableViewCellAccessoryNone;
    cell.thumbnailCache = self.thumbnailCache;
    cell.delegate = self;
  }
  cell.shouldConvolveImages = self.shouldConvolveImages;
  cell.imageProcessingQueue = _imageProcessingQueue;
  cell.imageProcessingSemaphore = _imageProcessingSemaphore;
  cell.photoUrls = [self.imageUrls subarrayWithRange:NSMakeRange(indexPath.row * kThumbnailsPerRow, kThumbnailsPerRow)];
  return cell;
}

- (CGFloat)tableView:(UITableView *)tableView heightForRowAtIndexPath:(NSIndexPath *)indexPath {
  return kThumbnailSize + 6.f;
}

- (void)photoGridCell:(PhotoGridTableCell *)cell didSelectPhotoAtUrl:(NSURL *)photoUrl {
  if (!self.detailViewController) {
    self.detailViewController = [[DetailViewController alloc] initWithNibName:@"DetailViewController" bundle:nil];
  }
  self.detailViewController.imageUrl = photoUrl;
  self.detailViewController.shouldUseGCD = self.shouldUseGCD;
  [self.navigationController pushViewController:self.detailViewController animated:YES];
}

- (BOOL)shouldAutorotateToInterfaceOrientation:(UIInterfaceOrientation)interfaceOrientation {
  return UIInterfaceOrientationIsPortrait(interfaceOrientation);
}

@end
