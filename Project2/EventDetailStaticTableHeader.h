//
//  EventDetailStaticTableHeader.h
//  Project2
//
//  Created by Sam Turnbull on 07/04/2015.
//  Copyright (c) 2015 Sam's Software. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "Event+Create.h"

@protocol EventDetailStaticTableHeaderDelegate;

@interface EventDetailStaticTableHeader : UITableViewController

@property (assign, nonatomic) id<EventDetailStaticTableHeaderDelegate> delegate;
@property (strong, nonatomic) Event *event;

@end

@protocol EventDetailStaticTableHeaderDelegate <NSObject>

- (void)didChangeEventName:(NSString *)eventName;

@end