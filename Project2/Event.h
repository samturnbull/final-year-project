//
//  Event.h
//  Project2
//
//  Created by Sam Turnbull on 31/03/2015.
//  Copyright (c) 2015 Sam's Software. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <CoreData/CoreData.h>

@class Photo, Photographer;

@interface Event : NSManagedObject

@property (nonatomic, retain) NSDate * dateCreated;
@property (nonatomic, retain) NSString * unique;
@property (nonatomic, retain) NSString * name;
@property (nonatomic, retain) NSSet *photographers;
@property (nonatomic, retain) NSSet *photos;
@end

@interface Event (CoreDataGeneratedAccessors)

- (void)addPhotographersObject:(Photographer *)value;
- (void)removePhotographersObject:(Photographer *)value;
- (void)addPhotographers:(NSSet *)values;
- (void)removePhotographers:(NSSet *)values;

- (void)addPhotosObject:(Photo *)value;
- (void)removePhotosObject:(Photo *)value;
- (void)addPhotos:(NSSet *)values;
- (void)removePhotos:(NSSet *)values;

@end
