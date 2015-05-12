//
//  EventStaticTableHeader.m
//  Project2
//
//  Created by Sam Turnbull on 06/04/2015.
//  Copyright (c) 2015 Sam's Software. All rights reserved.
//

#import "EventStaticTableHeader.h"
#import "EventViewController.h"

@interface EventStaticTableHeader () <UITextFieldDelegate>

@property (weak, nonatomic) IBOutlet UITextField *displayNameTextField;

@property (weak, nonatomic) IBOutlet UITableViewCell *displayNameCell;
@property (weak, nonatomic) IBOutlet UITableViewCell *createEventCell;
@property (weak, nonatomic) IBOutlet UITableViewCell *joinEventCell;
@property (weak, nonatomic) IBOutlet UITableViewCell *currentEventCell;

@end

@implementation EventStaticTableHeader

- (void)viewDidLoad
{
    self.displayNameTextField.text = self.displayName;
    if (self.currentEvent) {
        self.currentEventCell.textLabel.text = self.currentEvent.name;
        self.currentEventCell.detailTextLabel.text = [NSString stringWithFormat:@"%d photos from %d photographers. Invite Code %@", (int)self.currentEvent.photos.count, (int)self.currentEvent.photographers.count, self.currentEvent.uniqueCode];
    } else {
        self.currentEventCell.textLabel.text = @"No Event Selected";
        self.currentEventCell.textLabel.textColor = [UIColor grayColor];
        self.currentEventCell.detailTextLabel.hidden = YES;
    }
    
}

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath
{
    UITableViewCell *selectedCell = [self.tableView cellForRowAtIndexPath:indexPath];
    if (selectedCell == self.displayNameCell) {
        NSLog(@"display touched");
    } else if (selectedCell == self.createEventCell) {
        NSLog(@"create event touched");
        [self.delegate didTapCreateEventButton];
    } else if (selectedCell == self.joinEventCell) {
        NSLog(@"join event touched");
        [self.delegate didTapJoinEventButton];
    } else if (selectedCell == self.currentEventCell) {
        NSLog(@"current event touched");
    }
    [tableView deselectRowAtIndexPath:indexPath animated:YES];
}

- (BOOL)textFieldShouldReturn:(UITextField *)textField
{
    if([textField.text isEqualToString:@""]) {
        textField.text = [[UIDevice currentDevice] name];
        [self.delegate didChangeDisplayName:textField.text];
        [self.view endEditing:YES];
        return YES;
    } else if ([self isDisplayNameValid:textField.text]) {
        [self.delegate didChangeDisplayName:textField.text];
        [self.view endEditing:YES];
        return YES;
    }
    else {
        UIAlertView *alert = [[UIAlertView alloc] initWithTitle:@"Error" message:@"That is not a valid display name." delegate:nil cancelButtonTitle:@"OK" otherButtonTitles:nil];
        [alert show];
        return NO;
    }
}

- (BOOL)isDisplayNameValid:(NSString *)displayName
{
    MCPeerID *peerID;
    @try {
        peerID = [[MCPeerID alloc] initWithDisplayName:displayName];
    }
    @catch (NSException *exception) {
        NSLog(@"Invalid display name [%@]", displayName);
        return NO;
    }
    NSLog(@"Display name [%@] is valid", peerID.displayName);
    return YES;
}

-(void)viewWillDisappear:(BOOL)animated
{
    NSLog(@"container view will disappear");
}

@end
