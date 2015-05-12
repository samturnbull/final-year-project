//
//  EventViewController.h
//  Project2
//
//  Created by Sam Turnbull on 05/03/2015.
//  Copyright (c) 2015 Sam's Software. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "SessionContainer.h"
#import "CoreDataTableViewController.h"
#import "Event.h"

@protocol EventViewControllerDelegate;

@interface EventViewController : CoreDataTableViewController

@property (assign, nonatomic) id<EventViewControllerDelegate> delegate;
@property (copy, nonatomic) NSString *displayName;
@property (copy, nonatomic) NSString *serviceType;
@property (retain, nonatomic) SessionContainer *sessionContainer;
@property (strong, nonatomic) NSManagedObjectContext *managedObjectContext;
@property (strong, nonatomic) Event *currentEvent;

@end

@protocol EventViewControllerDelegate <NSObject>

- (void)controller:(EventViewController *)controller didSwitchToEvent:(Event *)event withDisplayName:(NSString *)name;

- (void)doneButtonTappedByEventController:(EventViewController *)controller;

@optional

- (void)didChangeDisplayName;

- (void)didTapCreateEventButton;

- (void)didTapJoinEventButton;

@end
