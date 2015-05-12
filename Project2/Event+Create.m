//
//  Event+Create.m
//  Project2
//
//  Created by Sam Turnbull on 25/03/2015.
//  Copyright (c) 2015 Sam's Software. All rights reserved.
//

#import "Event+Create.h"

@implementation Event (Create)

+ (NSString *)createUnique
{
    int a = arc4random_uniform(8)+1;
    int b = arc4random_uniform(9);
    int c = arc4random_uniform(9);
    int d = arc4random_uniform(9);
    NSString *unique = [NSString stringWithFormat:@"A%d%d%d%d", a, b, c, d];
    
    return unique;
}

//get unique code from unique attribute
- (NSString *)uniqueCode
{
    return [self.unique substringFromIndex:1];
}

+ (Event *)eventWithName:(NSString *)name
                  unique:(NSString *)unique
             dateCreated:(NSDate *)date
               inContext:(NSManagedObjectContext *)context;
{
    Event *event = nil;
    
    if ([unique length]) {
        //check if event with unique already exists in database:
        NSFetchRequest *request = [NSFetchRequest fetchRequestWithEntityName:@"Event"];
        request.predicate = [NSPredicate predicateWithFormat:@"unique = %@", unique];
        
        NSError *error;
        NSArray *matches = [context executeFetchRequest:request error:&error];
        
        if (!matches || ([matches count] > 1)) {
            //handle error
        } else if (![matches count]) {
            //if there's no matches, insert a new one
            event = [NSEntityDescription insertNewObjectForEntityForName:@"Event" inManagedObjectContext:context];
            event.unique = unique;
            event.dateCreated = date;
            if (name) {
                event.name = name;
            } else {
                NSFetchRequest *request = [NSFetchRequest fetchRequestWithEntityName:@"Event"];
                NSError *error;
                NSUInteger count = [context countForFetchRequest:request error:&error];
                if (count == NSNotFound) {
                    NSLog(@"Count fetch error: %@", error);
                }
                event.name = [NSString stringWithFormat:@"New Event %d", (int)count];
            }
        } else {
            event = [matches lastObject];
            if (name) {
                event.name = name;
            }
        }
    }
    
    return event;
}

@end
