//
//  Photo+Create.h
//  Project2
//
//  Created by Sam Turnbull on 25/03/2015.
//  Copyright (c) 2015 Sam's Software. All rights reserved.
//

#import "Photo.h"
#import <UIKit/UIKit.h>

@interface Photo (Create)

+ (NSString *)createUniqueWithPhotographerName:(NSString *)name;

+ (Photo *)photoWithData:(NSData *)data
                  unique:(NSString *)unique
               dateTaken:(NSDate *)date
            photographer:(Photographer *)photographer
                   event:(Event *)event
               inContext:(NSManagedObjectContext *)context;

+ (Photo *)photoWithImage:(UIImage *)image
                  unique:(NSString *)unique
               dateTaken:(NSDate *)date
            photographer:(Photographer *)photographer
                   event:(Event *)event
               inContext:(NSManagedObjectContext *)context;

+ (Photo *)photoWithImageUrl:(NSURL *)imageUrl
                   unique:(NSString *)unique
                dateTaken:(NSDate *)date
             photographer:(Photographer *)photographer
                    event:(Event *)event
                inContext:(NSManagedObjectContext *)context;

@end
