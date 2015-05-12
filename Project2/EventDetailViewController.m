//
//  CreateEventViewController.m
//  Project2
//
//  Created by Sam Turnbull on 27/03/2015.
//  Copyright (c) 2015 Sam's Software. All rights reserved.
//

#import "EventDetailViewController.h"
#import "EventDetailStaticTableHeader.h"
#import "Photographer.h"

@interface EventDetailViewController () <UITextFieldDelegate, EventDetailStaticTableHeaderDelegate>

@end

@implementation EventDetailViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    
    NSFetchRequest *fetchRequest = [NSFetchRequest fetchRequestWithEntityName:@"Photographer"];
    fetchRequest.sortDescriptors = @[[NSSortDescriptor sortDescriptorWithKey:@"name" ascending:YES]];

    // fetch only photographers for this event
    fetchRequest.predicate = [NSPredicate predicateWithFormat:@"%@ IN events", self.event];
    
    self.fetchedResultsController = [[NSFetchedResultsController alloc] initWithFetchRequest:fetchRequest
                                                                        managedObjectContext:self.event.managedObjectContext
                                                                          sectionNameKeyPath:nil
                                                                                   cacheName:nil];
    
    self.fetchedResultsController.delegate = self;
    
    NSError *error1 = nil;
    if ([self.fetchedResultsController performFetch:&error1]) {
        NSLog(@"Fetch performed, with %lu objects in fetchedobjects", (unsigned long)[self.fetchedResultsController.fetchedObjects count]);
    }
}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

#pragma mark - UITableViewDatasource methods

-(UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
    UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:@"Photographer Cell"];
    
    Photographer *photographer = [self.fetchedResultsController objectAtIndexPath:indexPath];
    
    NSFetchRequest *request = [[NSFetchRequest alloc] init];
    [request setEntity:[NSEntityDescription entityForName:@"Photo" inManagedObjectContext:self.event.managedObjectContext]];
    
    NSPredicate *predicate = [NSPredicate predicateWithFormat:@"event==%@ AND photographer==%@", self.event, photographer];
    [request setPredicate:predicate];
    
    NSError *err;
    NSUInteger count = [self.event.managedObjectContext countForFetchRequest:request error:&err];
    if(count == NSNotFound) {
        //Handle error
    }
    
    cell.textLabel.text = [NSString stringWithFormat:@"%@", photographer.name];
    cell.detailTextLabel.text = [NSString stringWithFormat:@"%d photos", (int)count];
    return cell;
}

- (NSString *)tableView:(UITableView *)tableView titleForHeaderInSection:(NSInteger)section
{
    return @"Photographers In Event:";
}

#pragma mark - Navigation

-(void)prepareForSegue:(UIStoryboardSegue *)segue sender:(id)sender
{
    if ([segue.identifier isEqualToString:@"Event Detail Static Table Header"]) {
        EventDetailStaticTableHeader *viewController = segue.destinationViewController;
        viewController.event = self.event;
        viewController.delegate = self;
    }
}

- (IBAction)doneButtonTapped:(id)sender
{
    [self.view endEditing:YES];
    [self.delegate doneButtonTappedByController:self];
}

- (IBAction)deleteButtonTapped:(id)sender
{
    UIAlertController* alert = [UIAlertController alertControllerWithTitle:nil
                                                                   message:@"All photos in this event will be permanently deleted."
                                                            preferredStyle:UIAlertControllerStyleActionSheet];
    
    UIAlertAction *defaultAction = [UIAlertAction actionWithTitle:@"Delete Event" style:UIAlertActionStyleDestructive handler:^(UIAlertAction *action) {
        [self.delegate controller:self didDeleteEvent:self.event];
        self.event = nil;
    }];
    UIAlertAction *cancelAction = [UIAlertAction actionWithTitle:@"Cancel" style:UIAlertActionStyleCancel handler:nil];
    
    [alert addAction:cancelAction];
    [alert addAction:defaultAction];
    
    //iPhone
    if (UI_USER_INTERFACE_IDIOM() == UIUserInterfaceIdiomPhone) {
        [self presentViewController:alert animated:YES completion:nil];
    }
    //iPad
    else {
        UIPopoverController *popup = [[UIPopoverController alloc] initWithContentViewController:alert];
        [popup presentPopoverFromBarButtonItem:sender permittedArrowDirections:UIPopoverArrowDirectionAny animated:YES];
    }
}

#pragma mark - EventDetailStaticTableHeaderDelegate methods

- (void)didChangeEventName:(NSString *)eventName
{
    self.event.name = eventName;
    [self.delegate controller:self didChangeEvent:self.event];
}

#pragma mark - UITextFieldDelegate methods

- (BOOL)textFieldShouldReturn:(UITextField *)textField
{
    [textField resignFirstResponder];
    [self.view endEditing:YES];
    return YES;
}

- (void)textFieldDidEndEditing:(UITextField *)textField
{
    [self.view endEditing:YES];
}

@end
