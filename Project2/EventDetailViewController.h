//
//  CreateEventViewController.h
//  Project2
//
//  Created by Sam Turnbull on 27/03/2015.
//  Copyright (c) 2015 Sam's Software. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "Event+Create.h"
#import "CoreDataTableViewController.h"

@protocol EventDetailViewControllerDelegate;

@interface EventDetailViewController : CoreDataTableViewController

@property (assign, nonatomic) id<EventDetailViewControllerDelegate> delegate;
@property (strong, nonatomic) Event *event;
@end

@protocol EventDetailViewControllerDelegate <NSObject>

- (void)controller:(EventDetailViewController *)controller didChangeEvent:(Event *)event;
- (void)controller:(EventDetailViewController *)controller didDeleteEvent:(Event *)event;

@optional

- (void)doneButtonTappedByController:(EventDetailViewController *)controller;

@end