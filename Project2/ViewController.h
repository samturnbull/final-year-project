//
//  ViewController.h
//  Project2
//
//  Created by Sam Turnbull on 05/03/2015.
//  Copyright (c) 2015 Sam's Software. All rights reserved.
//

#import <UIKit/UIKit.h>
#import <CoreData/CoreData.h>

@interface ViewController : UIViewController

@property (strong, nonatomic) NSManagedObjectContext *managedObjectContext;
@property (strong, nonatomic) NSFetchedResultsController *fetchedResultsController;

@end

