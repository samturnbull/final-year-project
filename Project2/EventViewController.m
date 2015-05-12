//
//  EventViewController.m
//  Project2
//
//  Created by Sam Turnbull on 05/03/2015.
//  Copyright (c) 2015 Sam's Software. All rights reserved.
//

@import MultipeerConnectivity;

#import "EventViewController.h"
#import "EventDetailViewController.h"
#import "Event+Create.h"
#import "EventStaticTableHeader.h"

@interface EventViewController () <UITextFieldDelegate, EventDetailViewControllerDelegate, UITableViewDelegate, EventStaticTableHeaderDelegate>

@end

@implementation EventViewController

- (void)viewDidLoad
{
    if (!self.currentEvent) {
        self.navigationItem.leftBarButtonItem.enabled = NO;
    }
    
    NSFetchRequest *fetchRequest = [NSFetchRequest fetchRequestWithEntityName:@"Event"];
    
    //we want all events except current event
    fetchRequest.predicate = [NSPredicate predicateWithFormat:@"unique != %@", self.currentEvent.unique];
    
    fetchRequest.sortDescriptors = @[[NSSortDescriptor sortDescriptorWithKey:@"dateCreated" ascending:NO]];
    
    self.fetchedResultsController = [[NSFetchedResultsController alloc] initWithFetchRequest:fetchRequest
                                                                        managedObjectContext:self.managedObjectContext
                                                                          sectionNameKeyPath:nil
                                                                                   cacheName:nil];
    
    self.fetchedResultsController.delegate = self;
    
    NSError *error1 = nil;
    if ([self.fetchedResultsController performFetch:&error1]) {
        NSLog(@"Fetch performed, with %lu objects in fetchedobjects", (unsigned long)[self.fetchedResultsController.fetchedObjects count]);
    }
}


#pragma mark - private

-(void)prepareForSegue:(UIStoryboardSegue *)segue sender:(id)sender
{
    if ([segue.identifier isEqualToString:@"Show Event Detail"]) {
        NSIndexPath *indexPath = [self.tableView indexPathForCell:sender];

        UINavigationController *navController = segue.destinationViewController;
        EventDetailViewController *viewController = (EventDetailViewController *)navController.topViewController;
        
        viewController.delegate = self;
        viewController.navigationItem.leftBarButtonItem = nil;
        Event *event = [self.fetchedResultsController objectAtIndexPath:indexPath];
        viewController.event = event;
    } else if ([segue.identifier isEqualToString:@"Event Static Table Header"]) {
        NSLog(@"prepare for segue called for event static embed segue");
        EventStaticTableHeader *viewController = segue.destinationViewController;
        viewController.displayName = self.displayName;
        viewController.delegate = self;
        viewController.currentEvent = self.currentEvent;
    }
}

#pragma mark - EventStaticTableHeaderDelegate methods

- (void)didChangeDisplayName:(NSString *)displayName
{
    self.displayName = displayName;
}

- (void)didTapCreateEventButton
{
    [Event eventWithName:nil
                  unique:[Event createUnique]
             dateCreated:[NSDate date]
               inContext:self.managedObjectContext];
}

- (void)didTapJoinEventButton
{
    UIAlertController* alert = [UIAlertController alertControllerWithTitle:@"Join Event"
                                                                   message:@"Enter the 4 digit code for the event you wish to join."
                                                            preferredStyle:UIAlertControllerStyleAlert];
    
    [alert addTextFieldWithConfigurationHandler:^(UITextField *textField) {
        textField.keyboardType = UIKeyboardTypeDecimalPad;
    }];
    
    UIAlertAction* defaultAction = [UIAlertAction actionWithTitle:@"Join" style:UIAlertActionStyleDefault
                                                          handler:^(UIAlertAction * action) {
                                                              UITextField *textfield = [[alert textFields] objectAtIndex:0];
                                                              NSString *inputtedEventCode = textfield.text;
                                                              if ([self isValidEventCode:inputtedEventCode]) {
                                                                  [self joinEventWithEventCode:inputtedEventCode];
                                                              } else {
                                                                  [self didTapJoinEventButton];
                                                              }
                                                          }];
    UIAlertAction* cancelAction = [UIAlertAction actionWithTitle:@"Cancel" style:UIAlertActionStyleCancel
                                                         handler:^(UIAlertAction * action) {
                                                             //handle
                                                         }];
    
    [alert addAction:cancelAction];
    [alert addAction:defaultAction];
    [self presentViewController:alert animated:YES completion:nil];
}

#pragma mark - IBAction methods

- (IBAction)doneButtonTapped:(id)sender {
    [self.delegate controller:self didSwitchToEvent:self.currentEvent withDisplayName:self.displayName];
}

- (void)joinEventWithEventCode:(NSString *)eventCode
{
    NSString *unique = [NSString stringWithFormat:@"A%@", eventCode];
    [Event eventWithName:nil
                  unique:unique
             dateCreated:[NSDate date]
               inContext:self.managedObjectContext];
}

- (BOOL)isValidEventCode:(NSString *)eventCode
{
    // check for validity
    if ([eventCode length] == 4) {
        BOOL isNumber;
        NSCharacterSet *digitSet = [NSCharacterSet decimalDigitCharacterSet];
        NSCharacterSet *codeSet = [NSCharacterSet characterSetWithCharactersInString:eventCode];
        isNumber = [digitSet isSupersetOfSet:codeSet];
        if (isNumber) {
            return YES;
        } else {
            return NO;
        }
    } else {
        return NO;
    }
}

- (void)viewWillDisappear:(BOOL)animated
{
    NSLog(@"event view will disappear");
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

#pragma mark - EventDetailViewControllerDelegate methods

- (void)controller:(EventDetailViewController *)controller didChangeEvent:(Event *)event
{
    [Event eventWithName:event.name
                  unique:event.unique
             dateCreated:event.dateCreated
               inContext:event.managedObjectContext];
}

-(void)controller:(EventDetailViewController *)controller didDeleteEvent:(Event *)event
{
    [self.navigationController popViewControllerAnimated:YES];
    if (event == self.currentEvent) {
        self.currentEvent = nil;
    }
    [self.managedObjectContext deleteObject:event];
}

#pragma mark - UITableViewDatasource methods

-(UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
    UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:@"Event Cell"];
    
    Event *event = [self.fetchedResultsController objectAtIndexPath:indexPath];
    
    if (event == self.currentEvent) {
        cell.backgroundColor = [UIColor colorWithRed:0.6 green:1.0 blue:0.5 alpha:1.0];
    }
    
    cell.textLabel.text = [NSString stringWithFormat:@"%@", event.name];
    cell.detailTextLabel.text = [NSString stringWithFormat:@"%d photos from %d photographers. Invite Code %@", (int)event.photos.count, (int)event.photographers.count, event.uniqueCode];
    return cell;
}

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath
{
    Event *event = [self.fetchedResultsController objectAtIndexPath:indexPath];
    [self.delegate controller:self didSwitchToEvent:event withDisplayName:self.displayName];
}

- (void)tableView:(UITableView *)tableView accessoryButtonTappedForRowWithIndexPath:(NSIndexPath *)indexPath
{
    // accesory button removed
}

- (NSString *)tableView:(UITableView *)tableView titleForHeaderInSection:(NSInteger)section
{
    NSInteger rows = 0;
    if ([[self.fetchedResultsController sections] count] > 0) {
        id <NSFetchedResultsSectionInfo> sectionInfo = [[self.fetchedResultsController sections] objectAtIndex:section];
        rows = [sectionInfo numberOfObjects];
    }
    if (rows > 0) {
        return @"Switch To Event";
    } else {
        return @"";
    }
}

- (void)tableView:(UITableView *)tableView commitEditingStyle:(UITableViewCellEditingStyle)editingStyle forRowAtIndexPath:(NSIndexPath *)indexPath {
    if (editingStyle == UITableViewCellEditingStyleDelete) {
        NSLog(@"delete tapped");
        UIAlertController* alert = [UIAlertController alertControllerWithTitle:nil
                                                                       message:@"All photos in this event will be permanently deleted."
                                                                preferredStyle:UIAlertControllerStyleActionSheet];
        
        UIAlertAction *defaultAction = [UIAlertAction actionWithTitle:@"Delete Event" style:UIAlertActionStyleDestructive handler:^(UIAlertAction *action) {
            Event *event = [self.fetchedResultsController objectAtIndexPath:indexPath];
            [self.managedObjectContext deleteObject:event];
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
            UITableViewCell *cell = [tableView cellForRowAtIndexPath:indexPath];
            UIView *deleteButton = [cell.subviews objectAtIndex:0];
            [popup presentPopoverFromRect:deleteButton.frame inView:deleteButton.superview permittedArrowDirections:UIPopoverArrowDirectionAny animated:YES];
        }
    }
}

@end
