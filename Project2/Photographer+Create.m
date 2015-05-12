//
//  Photographer+Create.m
//  Project2
//
//  Created by Sam Turnbull on 25/03/2015.
//  Copyright (c) 2015 Sam's Software. All rights reserved.
//

#import "Photographer+Create.h"

@implementation Photographer (Create)

+ (Photographer *)photographerWithName:(NSString *)name
                                 event:(Event *)event
                             inContext:(NSManagedObjectContext *)context
{
    Photographer *photographer = nil;
    
    if ([name length]) {
        //check if photographer with name already exists in database:
        NSFetchRequest *request = [NSFetchRequest fetchRequestWithEntityName:@"Photographer"];
        request.predicate = [NSPredicate predicateWithFormat:@"name = %@", name];
        
        NSError *error;
        NSArray *matches = [context executeFetchRequest:request error:&error];
        
        if (!matches || ([matches count] > 1)) {
            //handle error
        } else if (![matches count]) {
            //if there's no matches, insert a new one
            photographer = [NSEntityDescription insertNewObjectForEntityForName:@"Photographer" inManagedObjectContext:context];
            photographer.name = name;
            NSMutableSet *events = [photographer mutableSetValueForKey:@"events"];
            if(event) {
                [events addObject:event];
            } else {
                NSLog(@"Event is nil on new photographer");
            }
        } else {
            photographer = [matches lastObject];
            NSMutableSet *events = [photographer mutableSetValueForKey:@"events"];
            if(event) {
                [events addObject:event];
                NSLog(@"Added event to photographer %@", photographer.name);
            } else {
                NSLog(@"Event is nil on existing photographer");
            }
        }
    }
    
    return photographer;
}

@end
