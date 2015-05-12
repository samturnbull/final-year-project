//
//  EventStaticTableHeader.h
//  Project2
//
//  Created by Sam Turnbull on 06/04/2015.
//  Copyright (c) 2015 Sam's Software. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "Event+Create.h"

@protocol EventStaticTableHeaderDelegate;

@interface EventStaticTableHeader : UITableViewController

@property (assign, nonatomic) id<EventStaticTableHeaderDelegate> delegate;
@property (strong, nonatomic) NSString *displayName;
@property (strong, nonatomic) Event *currentEvent;

@end

@protocol EventStaticTableHeaderDelegate <NSObject>

- (void)didChangeDisplayName:(NSString *)displayName;

- (void)didTapCreateEventButton;

- (void)didTapJoinEventButton;

@end