//
//  Photo+Create.m
//  Project2
//
//  Created by Sam Turnbull on 25/03/2015.
//  Copyright (c) 2015 Sam's Software. All rights reserved.
//

#import "Photo+Create.h"
#import <ImageIO/ImageIO.h>

@implementation Photo (Create)

+ (NSString *)createUniqueWithPhotographerName:(NSString *)name
{
    NSDateFormatter *formatter = [[NSDateFormatter alloc] init];
    [formatter setDateFormat:@"yyMMdd-HHmmssSSSS"];
    NSString *unique = [NSString stringWithFormat:@"%@-%@.JPG", [formatter stringFromDate:[NSDate date]], name];
    
    return unique;
}

+ (Photo *)photoWithData:(NSData *)data
                  unique:(NSString *)unique
               dateTaken:(NSDate *)date
            photographer:(Photographer *)photographer
                   event:(Event *)event
               inContext:(NSManagedObjectContext *)context
{
    Photo *photo = nil;
    
    if ([unique length]) {
        //check if photo with unique already exists in database:
        NSFetchRequest *request = [NSFetchRequest fetchRequestWithEntityName:@"Photo"];
        request.predicate = [NSPredicate predicateWithFormat:@"unique = %@", unique];
        
        NSError *error;
        NSArray *matches = [context executeFetchRequest:request error:&error];
        
        if (!matches || ([matches count] > 1)) {
            //handle error
        } else if (![matches count]) {
            //if there's no matches, insert a new one
            //first convert uiimage thumbnail to data
            NSData *thumbnailData = UIImageJPEGRepresentation([self createThumbnailWithData:data], 0.5);
            
            photo = [NSEntityDescription insertNewObjectForEntityForName:@"Photo" inManagedObjectContext:context];
            photo.imageData = data;
            photo.unique = unique;
            photo.dateTaken = date;
            photo.photographer = photographer;
            photo.event = event;
            photo.thumbnailData = thumbnailData;
        } else {
            photo = [matches lastObject];
        }
    }
    
    return photo;
}

+ (Photo *)photoWithImage:(UIImage *)image
                   unique:(NSString *)unique
                dateTaken:(NSDate *)date
             photographer:(Photographer *)photographer
                    event:(Event *)event
                inContext:(NSManagedObjectContext *)context
{
    NSData *data = UIImageJPEGRepresentation(image, 1.0);
    
    return [Photo photoWithData:data
                  unique:unique
               dateTaken:date
            photographer:photographer
                   event:event
               inContext:context];
}

+ (Photo *)photoWithImageUrl:(NSURL *)imageUrl
                      unique:(NSString *)unique
                   dateTaken:(NSDate *)date
                photographer:(Photographer *)photographer
                       event:(Event *)event
                   inContext:(NSManagedObjectContext *)context
{
    NSData *data = [NSData dataWithContentsOfURL:imageUrl];
    
    return [Photo photoWithData:data
                         unique:unique
                      dateTaken:date
                   photographer:photographer
                          event:event
                      inContext:context];
}

+ (UIImage *)createThumbnailWithData:(NSData *)data
{
    CGImageSourceRef myImageSource = CGImageSourceCreateWithData((CFDataRef)data, NULL);
    
    CFDictionaryRef options = (__bridge CFDictionaryRef) @{
                              (id)kCGImageSourceThumbnailMaxPixelSize: @(500),
                              (id)kCGImageSourceCreateThumbnailFromImageAlways: @YES,
                              (id) kCGImageSourceCreateThumbnailWithTransform : @YES
                              };
    
    CGImageRef thumbnail = CGImageSourceCreateThumbnailAtIndex(myImageSource, 0, options);
    
    UIImage *thumbnailImage = [[UIImage alloc] initWithCGImage:thumbnail];
    
    CGImageRelease(thumbnail);
    //this seems to cause crashes:
    //CFRelease(options);
    
    return thumbnailImage;
}

@end
