//
//  Event+Create.h
//  Project2
//
//  Created by Sam Turnbull on 25/03/2015.
//  Copyright (c) 2015 Sam's Software. All rights reserved.
//

#import "Event.h"

@interface Event (Create)

+ (NSString *)createUnique;

+ (Event *)eventWithName:(NSString *)name
                    unique:(NSString *)unique
               dateCreated:(NSDate *)date
                 inContext:(NSManagedObjectContext *)context;

- (NSString *)uniqueCode;

@end
