//
//  Photo.h
//  Project2
//
//  Created by Sam Turnbull on 29/03/2015.
//  Copyright (c) 2015 Sam's Software. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <CoreData/CoreData.h>

@class Event, Photographer;

@interface Photo : NSManagedObject

@property (nonatomic, retain) NSDate * dateTaken;
@property (nonatomic, retain) NSData * imageData;
@property (nonatomic, retain) NSString * unique;
@property (nonatomic, retain) NSData * thumbnailData;
@property (nonatomic, retain) Event *event;
@property (nonatomic, retain) Photographer *photographer;

@end
