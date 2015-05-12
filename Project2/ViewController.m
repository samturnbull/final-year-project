//
//  ViewController.m
//  Project2
//
//  Created by Sam Turnbull on 05/03/2015.
//  Copyright (c) 2015 Sam's Software. All rights reserved.
//

@import MultipeerConnectivity;

#import "ViewController.h"
#import "EventViewController.h"
#import "SessionContainer.h"
#import "PhotoCell.h"
#import <MobileCoreServices/MobileCoreServices.h> //kUTTypeImage
#import "AppDelegate.h"
#import "Photo+Create.h"
#import "Photographer+Create.h"
#import "Event+Create.h"
#import "EventDetailViewController.h"

#import "JTSImageViewController.h"
#import "JTSImageInfo.h"

NSString * const kNSDefaultDisplayName = @"displayNameKey";
NSString * const kNSDefaultServiceType = @"serviceTypeKey";

@interface ViewController () <EventViewControllerDelegate, SessionContainerDelegate, UINavigationControllerDelegate, UIImagePickerControllerDelegate, UICollectionViewDataSource, UICollectionViewDelegateFlowLayout, UIContentContainer, NSFetchedResultsControllerDelegate, EventDetailViewControllerDelegate>

@property (copy, nonatomic) NSString *displayName;
@property (copy, nonatomic) NSString *serviceType; //event name
@property (retain, nonatomic) SessionContainer *sessionContainer;
@property (weak, nonatomic) IBOutlet UICollectionView *collectionView;
@property (nonatomic) BOOL selecting;
@property (strong, nonatomic) NSMutableArray *selectedPhotos;
@property (strong, nonatomic) Event *currentEvent;
@property (strong, nonatomic) Photographer *userPhotographer;

@end

@implementation ViewController
{
    NSMutableArray *_objectChanges;
    NSMutableArray *_sectionChanges;
}

- (void)awakeFromNib
{
    [[NSNotificationCenter defaultCenter] addObserverForName:@"DatabaseAvailabilityNotification"
                                                      object:nil
                                                       queue:nil
                                                  usingBlock:^(NSNotification *note) {
                                                      self.managedObjectContext = note.userInfo[@"Context"];
                                                  }];
}

- (void)setManagedObjectContext:(NSManagedObjectContext *)managedObjectContext
{
    _managedObjectContext = managedObjectContext;
    
    NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];
    self.displayName = [defaults objectForKey:kNSDefaultDisplayName];
    self.serviceType = [defaults objectForKey:kNSDefaultServiceType];
    
    //don't create event on first load. don't let user return from event screen without creating one
    if (self.serviceType) {
        self.currentEvent = [Event eventWithName:nil
                                          unique:self.serviceType
                                     dateCreated:[NSDate date]
                                       inContext:self.managedObjectContext];
    }
    
    //for testing
//    UIImage *image = [UIImage imageNamed:@"test.jpg"];
//    
//    for (int i=0; i<50; i++) {
//        
//        [Photo photoWithImage:image unique:[NSString stringWithFormat:@"%i",i] dateTaken:[NSDate date] photographer:self.userPhotographer event:self.currentEvent inContext:self.managedObjectContext];
//    }
    //end testing
    
    NSFetchRequest *fetchRequest = [NSFetchRequest fetchRequestWithEntityName:@"Photo"];
    
    fetchRequest.predicate = [NSPredicate predicateWithFormat:@"event.unique == %@", self.currentEvent.unique];
    fetchRequest.fetchBatchSize = 20;
    fetchRequest.sortDescriptors = @[[NSSortDescriptor sortDescriptorWithKey:@"dateTaken" ascending:NO]];

    self.fetchedResultsController = [[NSFetchedResultsController alloc] initWithFetchRequest:fetchRequest
                                                                        managedObjectContext:managedObjectContext
                                                                          sectionNameKeyPath:nil
                                                                                   cacheName:nil];
    
    self.fetchedResultsController.delegate = self;
    
    NSError *error1 = nil;
    if ([self.fetchedResultsController performFetch:&error1]) {
        NSLog(@"Fetch performed, with %lu objects in fetchedobjects", (unsigned long)[self.fetchedResultsController.fetchedObjects count]);
    }
}

- (void)setServiceType:(NSString *)serviceType
{
    //create event with this name
//    self.currentEvent = [Event eventWithName:self.displayName
//                                      unique:serviceType
//                                 dateCreated:[NSDate date]
//                                   inContext:self.managedObjectContext];

    //reset the predicate to match the new event
    NSPredicate *predicate = [NSPredicate predicateWithFormat:@"event.unique == %@", self.currentEvent.unique];
    [self.fetchedResultsController.fetchRequest setPredicate:predicate];
    
    //peform a new fetch
    NSError *error1 = nil;
    if (self.fetchedResultsController) {
        if (![self.fetchedResultsController performFetch:&error1]) {
            NSLog(@"Unresolved error %@, %@", error1, [error1 userInfo]);
            abort();
        }
    }
    
    //reload the collection view of photos
    [self.collectionView reloadData];
    
    _serviceType = serviceType;
}

- (void)setDisplayName:(NSString *)displayName
{
    //set photographer with display name
    self.userPhotographer = [Photographer photographerWithName:displayName
                                                         event:self.currentEvent
                                                     inContext:self.managedObjectContext];
    
    _displayName = displayName;
}

-(void)setCurrentEvent:(Event *)currentEvent
{
    [Photographer photographerWithName:self.displayName
                                 event:currentEvent
                             inContext:self.managedObjectContext];
    
    _currentEvent = currentEvent;
}

- (void)viewDidLoad {
    [super viewDidLoad];
    
    //remove blank space above collection view
    self.automaticallyAdjustsScrollViewInsets = NO;
    
    _objectChanges = [NSMutableArray array];
    _sectionChanges = [NSMutableArray array];
    
    if (self.displayName && self.serviceType) {
        [self updateTitleViewWithEvent:self.currentEvent];
        
        // create the session
        [self createSession];
    }
    else {
        // user needs to pick an event
        [self performSegueWithIdentifier:@"Show Events" sender:self];
    }
    self.selectedPhotos = [@[] mutableCopy];
}

- (void)updateTitleViewWithEvent:(Event *)event
{
    // from stackoverflow
    UILabel *titleLabel = [[UILabel alloc] initWithFrame:CGRectMake(0, -3, 0, 0)];
    titleLabel.backgroundColor = [UIColor clearColor];
    titleLabel.textColor = [UIColor blackColor];
    titleLabel.font = [UIFont systemFontOfSize:16];
    titleLabel.text = event.name;
    [titleLabel sizeToFit];
    
    UILabel *subTitleLabel = [[UILabel alloc] initWithFrame:CGRectMake(0, 18, 0, 0)];
    subTitleLabel.backgroundColor = [UIColor clearColor];
    subTitleLabel.textColor = [UIColor blackColor];
    subTitleLabel.font = [UIFont systemFontOfSize:11];
    subTitleLabel.text = [NSString stringWithFormat:@"Invite Code %@", event.uniqueCode];
    [subTitleLabel sizeToFit];
    
    UIView *twoLineTitleView = [[UIView alloc] initWithFrame:CGRectMake(0, 0, MAX(subTitleLabel.frame.size.width, titleLabel.frame.size.width), 30)];
    [twoLineTitleView addSubview:titleLabel];
    [twoLineTitleView addSubview:subTitleLabel];
    
    float widthDiff = subTitleLabel.frame.size.width - titleLabel.frame.size.width;
    
    if (widthDiff > 0) {
        CGRect frame = titleLabel.frame;
        frame.origin.x = widthDiff / 2;
        titleLabel.frame = CGRectIntegral(frame);
    }else{
        CGRect frame = subTitleLabel.frame;
        frame.origin.x = abs(widthDiff) / 2;
        subTitleLabel.frame = CGRectIntegral(frame);
    }
    
    self.navigationItem.titleView = twoLineTitleView;
}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

-(BOOL)shouldPerformSegueWithIdentifier:(NSString *)identifier sender:(id)sender
{
     if ([identifier isEqualToString:@"Show Photo"]) {
         if (self.selecting) {
             return NO;
         }
     }
    return YES;
}

- (void)prepareForSegue:(UIStoryboardSegue *)segue sender:(id)sender
{
    if ([segue.identifier isEqualToString:@"Show Events"]) {
        UINavigationController *navController = segue.destinationViewController;
        EventViewController *viewController = (EventViewController *)navController.topViewController;
        viewController.delegate = self;
        
        if(![self.displayName length]) {
            viewController.displayName = [[UIDevice currentDevice] name];
        } else {
            viewController.displayName = self.displayName;
        }
        viewController.serviceType = self.serviceType;
        viewController.sessionContainer = self.sessionContainer;
        viewController.managedObjectContext = self.managedObjectContext;
        viewController.currentEvent = self.currentEvent;
    }
    if ([segue.identifier isEqualToString:@"Show Event Detail Shortcut"]) {
        UINavigationController *navController = segue.destinationViewController;
        EventDetailViewController *viewController = (EventDetailViewController *)navController.topViewController;
        viewController.delegate = self;
        viewController.event = self.currentEvent;
    }
}

#pragma mark - EventDetailViewControllerDelegate methods

- (void)controller:(EventDetailViewController *)controller didChangeEvent:(Event *)event
{
    if (!event.isDeleted) {
        [Event eventWithName:event.name
                      unique:event.unique
                 dateCreated:event.dateCreated
                   inContext:event.managedObjectContext];
        
        [self updateTitleViewWithEvent:event];
    }
}

-(void)controller:(EventDetailViewController *)controller didDeleteEvent:(Event *)event
{
    [self dismissViewControllerAnimated:YES completion:nil];
    if (event == self.currentEvent) {
        self.currentEvent = nil;
    }
    self.navigationItem.titleView = nil;
    [self.managedObjectContext deleteObject:event];
    [self performSegueWithIdentifier:@"Show Events" sender:nil];
}

- (void)doneButtonTappedByController:(EventDetailViewController *)controller
{
    [self dismissViewControllerAnimated:YES completion:nil];
}

#pragma mark - EventViewControllerDelegate methods

- (void)controller:(EventViewController *)controller didSwitchToEvent:(Event *)event withDisplayName:(NSString *)name
{
    if (![event.unique isEqualToString:self.currentEvent.unique] || ![name isEqualToString:self.displayName]) {
        NSLog(@"either the event or the displayname has changed, so session will restart");
        
        // Save displayname and servicetype for subsequent app launches
        NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];
        [defaults setObject:name forKey:kNSDefaultDisplayName];
        [defaults setObject:event.unique forKey:kNSDefaultServiceType];
        [defaults synchronize];
        
        self.currentEvent = event;
        self.serviceType = event.unique;
        self.displayName = name;
        [self createSession];
        [self updateTitleViewWithEvent:event];
    }

    NSLog(@"did switch to event called with event name: %@ unique: %@", event.name, event.unique);
    [self dismissViewControllerAnimated:YES completion:nil];
}

- (void)doneButtonTappedByEventController:(EventViewController *)controller
{
    [self dismissViewControllerAnimated:YES completion:nil];
}

#pragma mark - SessionContainerDelegate methods

- (void)connectedToPeer:(MCPeerID *)peer
{
    dispatch_async(dispatch_get_main_queue(), ^{
        NSLog(@"connected to peer [%@] so photographer created and they are being sent a request for array of photo uniques", peer.displayName);
        [Photographer photographerWithName:peer.displayName event:self.currentEvent inContext:self.managedObjectContext];
        NSMutableArray *photoIDs = [[NSMutableArray alloc] init];
        
        NSLog(@"fetchedobjects has [%d] in it", (int)[self.fetchedResultsController.fetchedObjects count]);
        for (Photo *photo in self.fetchedResultsController.fetchedObjects) {
            [photoIDs addObject:photo.unique];
        }
        
        NSLog(@"photoIDs has [%d] uniques in it", (int)[photoIDs count]);
        [self.sessionContainer sendPhotoIDsArray:photoIDs toPeer:peer];
    });
}

- (void)receivedRequestForPhotoIDsArrayFromPeer:(MCPeerID *)peer{

    NSLog(@"received request for array of photo uniques from peer [%@]", peer.displayName);
    
    NSMutableArray *photoIDs = [[NSMutableArray alloc] init];
    
    NSLog(@"fetchedobjects has [%d] in it", (int)[self.fetchedResultsController.fetchedObjects count]);
    for (Photo *photo in self.fetchedResultsController.fetchedObjects) {
        [photoIDs addObject:photo.unique];
    }
    
    NSLog(@"photoIDs has [%d] uniques in it", (int)[photoIDs count]);
    [self.sessionContainer sendPhotoIDsArray:photoIDs toPeer:peer];
}

- (void)receivedPhotoIDsArray:(NSArray *)photoIDs fromPeer:(MCPeerID *)peer {
    
    NSLog(@"received array of [%d] photo uniques from peer [%@]", (int)[photoIDs count], peer.displayName);
    
    NSSet *receivedPhotoIDsSet = [NSSet setWithArray:photoIDs];
    NSMutableSet *fetchedObjectIDsSet = [[NSMutableSet alloc] init];
    
    for (Photo *photo in self.fetchedResultsController.fetchedObjects) {
        [fetchedObjectIDsSet addObject:photo.unique];
    }
    
    NSLog(@"peer has [%d] in their array of photos, I have [%d] in mine", (int)[receivedPhotoIDsSet count], (int)[fetchedObjectIDsSet count]);
    
    [fetchedObjectIDsSet minusSet:receivedPhotoIDsSet];
    NSLog(@"there are [%d] photos left in the set that I have, that peer [%@] does not have", (int)[fetchedObjectIDsSet count], peer.displayName);
    
    for (NSString *unique in fetchedObjectIDsSet) {
        NSFetchRequest *request = [NSFetchRequest fetchRequestWithEntityName:@"Photo"];
        request.predicate = [NSPredicate predicateWithFormat:@"unique = %@", unique];
        NSError *error;
        NSArray *matches = [self.managedObjectContext executeFetchRequest:request error:&error];
        Photo *photo = [matches lastObject];
        NSLog(@"photo retrieved from core data with unique [%@], to be sent to peer [%@]", unique, peer.displayName);
        
        [self.sessionContainer sendPhotoWithData:photo.imageData withName:photo.unique toPeer:peer];
    }
}

- (void)receivedPhotoAtURL:(NSURL *)imageUrl withName:(NSString *)name fromPeer:(MCPeerID *)peer
{
        dispatch_async(dispatch_get_main_queue(), ^{
            
            NSString *photographerName = [[name substringToIndex:[name length] -4] substringFromIndex:18];
            NSLog(@"photographer name from the file name is: [%@]", photographerName);
            
            Photographer *photographer = [Photographer photographerWithName:photographerName
                                                                      event:self.currentEvent
                                                                  inContext:self.managedObjectContext];
            
            [Photo photoWithImageUrl:imageUrl
                              unique:name
                           dateTaken:[NSDate date]
                        photographer:photographer
                               event:self.currentEvent
                           inContext:self.managedObjectContext];
            
            NSLog(@"Received photo with name [%@] from peer [%@]", name, peer.displayName);
        });
}

#pragma mark - UIImagePickerDelegate methods

-(void)imagePickerController:(UIImagePickerController *)picker didFinishPickingMediaWithInfo:(NSDictionary *)info
{
    [self.collectionView.collectionViewLayout invalidateLayout];
    UIImage *image = info[UIImagePickerControllerEditedImage];
    if (!image) image = info[UIImagePickerControllerOriginalImage];
    
    [self dismissViewControllerAnimated:YES completion:NULL];
    
    NSString *name = [Photo createUniqueWithPhotographerName:self.userPhotographer.name];
    
    [Photo photoWithImage:image unique:name
                dateTaken:[NSDate date]
             photographer:self.userPhotographer
                    event:self.currentEvent
                inContext:self.managedObjectContext];
    
    [self.sessionContainer sendToAllPeersPhoto:image withName:name];
}

-(void)imagePickerControllerDidCancel:(UIImagePickerController *)picker
{
    [self.collectionView.collectionViewLayout invalidateLayout];
    [self dismissViewControllerAnimated:YES completion:NULL];
}

#pragma mark - Private methods

- (void)createSession
{
    [self.sessionContainer invalidateSessionContainer];
    self.sessionContainer = [[SessionContainer alloc] initWithDisplayName:self.displayName serviceType:self.serviceType];
    _sessionContainer.delegate = self;
}

- (void)setUpStandardBarButtons
{
    //set navigation left button to event button
    UIBarButtonItem *eventButton = [[UIBarButtonItem alloc] initWithTitle:@"Events"
                                                                    style:UIBarButtonItemStylePlain
                                                                   target:self
                                                                   action:@selector(eventButtonTapped:)];
    [self.navigationItem setLeftBarButtonItem:eventButton animated:YES];
    
    //set navigation right button back to event details button
    
    UIBarButtonItem *eventInfoButton = [[UIBarButtonItem alloc] initWithTitle:@"Event Details"
                                                                        style:UIBarButtonItemStylePlain
                                                                       target:self
                                                                       action:@selector(eventInfoButtonTapped:)];
    
    [self.navigationItem setRightBarButtonItem:eventInfoButton animated:YES];
    
    
    //set toolbar bottom left to select button
    UIBarButtonItem *selectButton = [[UIBarButtonItem alloc]
                                     initWithTitle:@"Select"
                                     style:UIBarButtonItemStylePlain
                                     target:self
                                     action:@selector(selectButtonTapped:)];
    
    //set toolbar middle button to camera button
    UIBarButtonItem *cameraButton = [[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemCamera
                                                                                  target:self
                                                                                  action:@selector(takePhotoTapped:)];
    
    //set toolbar right button to add photos button
    UIBarButtonItem *addPhotosButton = [[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemAdd
                                                                                  target:self
                                                                                  action:@selector(addPhotoTapped:)];
    
    //flexible spacer
    UIBarButtonItem *flex = [[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemFlexibleSpace
                                                                          target:self
                                                                          action:nil];
    
    
    
    [self setToolbarItems:@[selectButton, flex, cameraButton, flex, addPhotosButton] animated:YES];
}

- (void)setUpSelectModeBarButtons
{
    //set navigation left button to nothing
    [self.navigationItem setLeftBarButtonItem:nil animated:YES];
    
    //set navigation right button to select all
    UIBarButtonItem *selectAllButton = [[UIBarButtonItem alloc]
                                        initWithTitle:@"Select All"
                                        style:UIBarButtonItemStylePlain
                                        target:self
                                        action:@selector(selectAllButtonTapped:)];
    [self.navigationItem setRightBarButtonItem:selectAllButton animated:YES];
    
    //set toolbar bottom left to a share button
    UIBarButtonItem *shareButton = [[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemAction
                                                                                 target:self
                                                                                 action:@selector(shareButtonTapped:)];
    shareButton.enabled = NO;
    
    //set toolbar middle to flex space
    UIBarButtonItem *flex = [[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemFlexibleSpace
                                                                          target:self
                                                                          action:nil];
    
    //set toolbar bottom right to done button
    UIBarButtonItem *cancelButton = [[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemCancel
                                                                                target:self
                                                                                action:@selector(doneButtonTapped:)];
    
    //set toolbar bottom right to delete button
    UIBarButtonItem *deleteButton = [[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemTrash
                                                                                  target:self
                                                                                  action:@selector(deleteButtonTapped:)];
    deleteButton.enabled = NO;
    
    [self setToolbarItems:@[cancelButton, flex, shareButton, flex, deleteButton] animated:YES];
}

- (IBAction)takePhotoTapped:(id)sender
{
    UIImagePickerController *uiipc = [[UIImagePickerController alloc] init];
    
    //check whether camera is available so it doesn't crash the simulator
    if([UIImagePickerController isSourceTypeAvailable:UIImagePickerControllerSourceTypeCamera]) {
        uiipc.sourceType = UIImagePickerControllerSourceTypeCamera;
    } else if([UIImagePickerController isSourceTypeAvailable:UIImagePickerControllerSourceTypePhotoLibrary]) {
        uiipc.sourceType = UIImagePickerControllerSourceTypePhotoLibrary;
    } else {
        uiipc.sourceType = UIImagePickerControllerSourceTypeSavedPhotosAlbum;
    }
    
    uiipc.delegate = self;
    uiipc.mediaTypes = @[(NSString *)kUTTypeImage];
    //uiipc.sourceType = UIImagePickerControllerSourceTypeCamera;
    uiipc.allowsEditing = NO;
    [self presentViewController:uiipc animated:YES completion:NULL];
}

- (IBAction)addPhotoTapped:(id)sender {
    UIImagePickerController *uiipc = [[UIImagePickerController alloc] init];
    
    if([UIImagePickerController isSourceTypeAvailable:UIImagePickerControllerSourceTypePhotoLibrary]) {
        uiipc.sourceType = UIImagePickerControllerSourceTypePhotoLibrary;
    } else {
        uiipc.sourceType = UIImagePickerControllerSourceTypeSavedPhotosAlbum;
    }
    
    uiipc.delegate = self;
    uiipc.mediaTypes = @[(NSString *)kUTTypeImage];
    //uiipc.sourceType = UIImagePickerControllerSourceTypeCamera;
    uiipc.allowsEditing = NO;
    
    //iPhone
    if (UI_USER_INTERFACE_IDIOM() == UIUserInterfaceIdiomPhone) {
        [self presentViewController:uiipc animated:YES completion:nil];
    }
    //iPad
    else {
        UIPopoverController *popup = [[UIPopoverController alloc] initWithContentViewController:uiipc];
        [popup presentPopoverFromBarButtonItem:sender permittedArrowDirections:UIPopoverArrowDirectionAny animated:YES];
    }
}

- (IBAction)selectButtonTapped:(id)sender
{
    [self setUpSelectModeBarButtons];
    self.selecting = YES;
    [self.collectionView setAllowsMultipleSelection:YES];
    
    //reload cells to add checkmark
    [self.collectionView reloadData];
}

- (void)doneButtonTapped:(id)sender
{
    [self setUpStandardBarButtons];
    
    self.selecting = NO;

    //deselect all selected cells
    for (NSIndexPath *indexPath in self.collectionView.indexPathsForSelectedItems) {
        [self.collectionView deselectItemAtIndexPath:indexPath animated:NO];
    }
    [self.collectionView setAllowsMultipleSelection:NO];
    [self.selectedPhotos removeAllObjects];
    
    //reload cells to remove checkmark
    [self.collectionView reloadData];
}

- (void)eventButtonTapped:(id)sender
{
    [self performSegueWithIdentifier:@"Show Events" sender:self];
}

- (void)selectAllButtonTapped:(id)sender
{
    [self.selectedPhotos removeAllObjects];
    NSLog(@"select all tapped with sender %@", sender);
    for (int i = 0; i < [self.collectionView numberOfItemsInSection:0]; i++) {
        NSIndexPath *indexPath = [NSIndexPath indexPathForRow:i inSection:0];
        [self.collectionView selectItemAtIndexPath:indexPath animated:NO scrollPosition:UICollectionViewScrollPositionNone];
        Photo *photo = [self.fetchedResultsController objectAtIndexPath:indexPath];
        [self.selectedPhotos addObject:photo];
    }
    UIBarButtonItem *shareButton = [self.toolbarItems objectAtIndex:2];
    shareButton.enabled = YES;
    UIBarButtonItem *deleteButton = [self.toolbarItems objectAtIndex:4];
    deleteButton.enabled = YES;
}

- (void)eventInfoButtonTapped:(id)sender
{
    NSLog(@"event info tapped with sender %@", sender);
    [self performSegueWithIdentifier:@"Show Event Detail Shortcut" sender:self];
}

- (void)shareButtonTapped:(id)sender
{
    NSLog(@"share button tapped with sender %@", sender);
    if ([self.selectedPhotos count] > 0) {
        NSMutableArray *selectedPhotosAsImages = [[NSMutableArray alloc] init];
        for (Photo *photo in self.selectedPhotos) {
            UIImage *image = [UIImage imageWithData:photo.imageData];
            [selectedPhotosAsImages addObject:image];
        }
        
        UIActivityViewController *shareSheet = [[UIActivityViewController alloc] initWithActivityItems:selectedPhotosAsImages applicationActivities:nil];
        
        //iPhone
        if (UI_USER_INTERFACE_IDIOM() == UIUserInterfaceIdiomPhone) {
            [self presentViewController:shareSheet animated:YES completion:nil];
        }
        //iPad
        else {
            UIPopoverController *popup = [[UIPopoverController alloc] initWithContentViewController:shareSheet];
            [popup presentPopoverFromBarButtonItem:sender permittedArrowDirections:UIPopoverArrowDirectionAny animated:YES];
        }
    }
}

- (void)deleteButtonTapped:(id)sender
{
    NSLog(@"delete button tapped with sender %@", sender);
    if ([self.selectedPhotos count] > 0) {
        
        UIAlertController* alert = [UIAlertController alertControllerWithTitle:nil
                                                                       message:@"Selected photos will be permanently deleted."
                                                                preferredStyle:UIAlertControllerStyleActionSheet];
        
        UIAlertAction *defaultAction = [UIAlertAction actionWithTitle:[NSString stringWithFormat:@"Delete %d Photos", (int)[self.selectedPhotos count]]
                                                                style:UIAlertActionStyleDestructive
                                                              handler:^(UIAlertAction *action) {
                                                                  for (Photo *photo in self.selectedPhotos) {
                                                                      [self.managedObjectContext deleteObject:photo];
                                                                  }
                                                                  [self.selectedPhotos removeAllObjects];
                                                                  UIBarButtonItem *shareButton = [self.toolbarItems objectAtIndex:2];
                                                                  shareButton.enabled = NO;
                                                                  UIBarButtonItem *deleteButton = [self.toolbarItems objectAtIndex:4];
                                                                  deleteButton.enabled = NO;
                                                              }];
        
        UIAlertAction *cancelAction = [UIAlertAction actionWithTitle:@"Cancel" style:UIAlertActionStyleCancel handler:nil];
        
        [alert addAction:cancelAction];
        [alert addAction:defaultAction];
        
        //iPhone
        if (UI_USER_INTERFACE_IDIOM() == UIUserInterfaceIdiomPhone) {
            [self presentViewController:alert animated:YES completion:nil];
        }
        //iPad
        else {
            UIPopoverController *popup = [[UIPopoverController alloc] initWithContentViewController:alert];
            [popup presentPopoverFromBarButtonItem:sender permittedArrowDirections:UIPopoverArrowDirectionAny animated:YES];
        }
    }
}

#pragma mark - UICollectionView Datasource

- (NSInteger)collectionView:(UICollectionView *)view numberOfItemsInSection:(NSInteger)section
{
    id <NSFetchedResultsSectionInfo> sectionInfo = [self.fetchedResultsController sections][section];

    return [sectionInfo numberOfObjects];
}

- (UICollectionViewCell *)collectionView:(UICollectionView *)cv cellForItemAtIndexPath:(NSIndexPath *)indexPath
{
    PhotoCell *cell = [cv dequeueReusableCellWithReuseIdentifier:@"PhotoCell" forIndexPath:indexPath];
    Photo *photo = (Photo *)[self.fetchedResultsController objectAtIndexPath:indexPath];
    UIImage *thumbnail = [UIImage imageWithData:photo.thumbnailData];
    
    cell.photo = thumbnail;
    
     //hide/show checkmarks based on selection mode
    if (self.selecting) {
        cell.checkMarkView.hidden = NO;
    } else {
        cell.checkMarkView.hidden = YES;
    }
    
    //should increase scrolling performance
    cell.layer.shouldRasterize = YES;
    cell.layer.rasterizationScale = [UIScreen mainScreen].scale;
    
    return cell;
}

#pragma mark - UICollectionViewDelegate
- (void)collectionView:(UICollectionView *)collectionView didSelectItemAtIndexPath:(NSIndexPath *)indexPath
{
    if (!self.selecting) {
        [self.collectionView deselectItemAtIndexPath:indexPath animated:NO];
        
        JTSImageInfo *imageInfo = [[JTSImageInfo alloc] init];

        Photo *photo = (Photo *)[self.fetchedResultsController objectAtIndexPath:indexPath];
        UIImage *photoImage = [UIImage imageWithData:photo.imageData];
        imageInfo.image = photoImage;

        UICollectionViewCell *cell = [collectionView cellForItemAtIndexPath:indexPath];
        imageInfo.referenceRect = cell.frame;
        imageInfo.referenceView = cell.superview;
        imageInfo.referenceContentMode = cell.contentMode;
        imageInfo.referenceCornerRadius = cell.layer.cornerRadius;
        
        JTSImageViewController *imageViewer = [[JTSImageViewController alloc]
                                               initWithImageInfo:imageInfo
                                               mode:JTSImageViewControllerMode_Image
                                               backgroundStyle:JTSImageViewControllerBackgroundOption_Scaled];
        
        [imageViewer showFromViewController:self transition:JTSImageViewControllerTransition_FromOriginalPosition];

    } else {
        Photo *photo = (Photo *)[self.fetchedResultsController objectAtIndexPath:indexPath];
        [self.selectedPhotos addObject:photo];
        NSLog(@"added %@ to selected photos", photo.unique);
        
        UIBarButtonItem *shareButton = [self.toolbarItems objectAtIndex:2];
        shareButton.enabled = YES;
        UIBarButtonItem *deleteButton = [self.toolbarItems objectAtIndex:4];
        deleteButton.enabled = YES;
    }
    
}
- (void)collectionView:(UICollectionView *)collectionView didDeselectItemAtIndexPath:(NSIndexPath *)indexPath
{
    if (self.selecting) {
        Photo *photo = (Photo *)[self.fetchedResultsController objectAtIndexPath:indexPath];
        [self.selectedPhotos removeObject:photo];
        if (![self.selectedPhotos count]) {
            UIBarButtonItem *shareButton = [self.toolbarItems objectAtIndex:2];
            shareButton.enabled = NO;
            UIBarButtonItem *deleteButton = [self.toolbarItems objectAtIndex:4];
            deleteButton.enabled = NO;
        }
    }
}

#pragma mark - UICollectionViewDelegateFlowLayout

- (CGSize)collectionView:(UICollectionView *)collectionView layout:(UICollectionViewLayout*)collectionViewLayout sizeForItemAtIndexPath:(NSIndexPath *)indexPath
{
    float viewWidth = self.view.frame.size.width;
    float viewHeight = self.view.frame.size.height;
    float itemSpacing = 1; //to match minimumInteritemSpacingForSectionAtIndex method below
    
    float itemsPerRow = (viewWidth < viewHeight) ? 4 : 7; //4 in portrait, 7 in landscape

    float cellHeight = (viewWidth/itemsPerRow) - (((itemsPerRow - 1) * itemSpacing)/itemsPerRow)-0.1;
    float cellWidth = cellHeight;
    
    CGSize size = CGSizeMake(cellWidth, cellHeight);
    return size;
}

- (UIEdgeInsets)collectionView:(UICollectionView *)collectionView layout:(UICollectionViewLayout*)collectionViewLayout insetForSectionAtIndex:(NSInteger)section
{
    return UIEdgeInsetsMake(0, 0, 0, 0);
}

- (CGFloat) collectionView:(UICollectionView *)collectionView layout:(UICollectionViewLayout *)collectionViewLayout minimumLineSpacingForSectionAtIndex:(NSInteger)section
{
    return 1;
}

- (CGFloat) collectionView:(UICollectionView *)collectionView layout:(UICollectionViewLayout *)collectionViewLayout minimumInteritemSpacingForSectionAtIndex:(NSInteger)section
{
    return 1;
}

- (CGSize)collectionView:(UICollectionView *)collectionView layout:(UICollectionViewLayout *)collectionViewLayout referenceSizeForHeaderInSection:(NSInteger)section
{
    return CGSizeZero;
}

#pragma mark - UIContentContainer delegate

- (void)viewWillTransitionToSize:(CGSize)size withTransitionCoordinator:(id <UIViewControllerTransitionCoordinator>)coordinator NS_AVAILABLE_IOS(8_0)
{
    [self.collectionView.collectionViewLayout invalidateLayout];
    return;
}

#pragma mark - NSFetchedResultsControllerDelegate

- (void)controller:(NSFetchedResultsController *)controller didChangeSection:(id <NSFetchedResultsSectionInfo>)sectionInfo
           atIndex:(NSUInteger)sectionIndex forChangeType:(NSFetchedResultsChangeType)type
{
    
    NSMutableDictionary *change = [NSMutableDictionary new];
    
    switch(type) {
        case NSFetchedResultsChangeInsert:
            change[@(type)] = @(sectionIndex);
            break;
        case NSFetchedResultsChangeDelete:
            change[@(type)] = @(sectionIndex);
            break;
    }
    
    [_sectionChanges addObject:change];
}

- (void)controller:(NSFetchedResultsController *)controller didChangeObject:(id)anObject
       atIndexPath:(NSIndexPath *)indexPath forChangeType:(NSFetchedResultsChangeType)type
      newIndexPath:(NSIndexPath *)newIndexPath
{
    
    NSMutableDictionary *change = [NSMutableDictionary new];
    switch(type)
    {
        case NSFetchedResultsChangeInsert:
            change[@(type)] = newIndexPath;
            break;
        case NSFetchedResultsChangeDelete:
            change[@(type)] = indexPath;
            break;
        case NSFetchedResultsChangeUpdate:
            change[@(type)] = indexPath;
            break;
        case NSFetchedResultsChangeMove:
            change[@(type)] = @[indexPath, newIndexPath];
            break;
    }
    [_objectChanges addObject:change];
}

- (void)controllerDidChangeContent:(NSFetchedResultsController *)controller
{
    if ([_sectionChanges count] > 0)
    {
        [self.collectionView performBatchUpdates:^{
            
            for (NSDictionary *change in _sectionChanges)
            {
                [change enumerateKeysAndObjectsUsingBlock:^(NSNumber *key, id obj, BOOL *stop) {
                    
                    NSFetchedResultsChangeType type = [key unsignedIntegerValue];
                    switch (type)
                    {
                        case NSFetchedResultsChangeInsert:
                            [self.collectionView insertSections:[NSIndexSet indexSetWithIndex:[obj unsignedIntegerValue]]];
                            break;
                        case NSFetchedResultsChangeDelete:
                            [self.collectionView deleteSections:[NSIndexSet indexSetWithIndex:[obj unsignedIntegerValue]]];
                            break;
                        case NSFetchedResultsChangeUpdate:
                            [self.collectionView reloadSections:[NSIndexSet indexSetWithIndex:[obj unsignedIntegerValue]]];
                            break;
                    }
                }];
            }
        } completion:nil];
    }
    
    if ([_objectChanges count] > 0 && [_sectionChanges count] == 0)
    {
        [self.collectionView performBatchUpdates:^{
            
            for (NSDictionary *change in _objectChanges)
            {
                [change enumerateKeysAndObjectsUsingBlock:^(NSNumber *key, id obj, BOOL *stop) {
                    
                    NSFetchedResultsChangeType type = [key unsignedIntegerValue];
                    switch (type)
                    {
                        case NSFetchedResultsChangeInsert:
                            [self.collectionView insertItemsAtIndexPaths:@[obj]];
                            break;
                        case NSFetchedResultsChangeDelete:
                            [self.collectionView deleteItemsAtIndexPaths:@[obj]];
                            break;
                        case NSFetchedResultsChangeUpdate:
                            [self.collectionView reloadItemsAtIndexPaths:@[obj]];
                            break;
                        case NSFetchedResultsChangeMove:
                            [self.collectionView moveItemAtIndexPath:obj[0] toIndexPath:obj[1]];
                            break;
                    }
                }];
            }
        } completion:nil];
    }
    
    [_sectionChanges removeAllObjects];
    [_objectChanges removeAllObjects];
}

@end
