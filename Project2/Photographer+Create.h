//
//  Photographer+Create.h
//  Project2
//
//  Created by Sam Turnbull on 25/03/2015.
//  Copyright (c) 2015 Sam's Software. All rights reserved.
//

#import "Photographer.h"

@interface Photographer (Create)

+ (Photographer *)photographerWithName:(NSString *)name
                                 event:(Event *)event
                             inContext:(NSManagedObjectContext *)context;

@end
