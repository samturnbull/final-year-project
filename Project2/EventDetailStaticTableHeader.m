//
//  EventDetailStaticTableHeader.m
//  Project2
//
//  Created by Sam Turnbull on 07/04/2015.
//  Copyright (c) 2015 Sam's Software. All rights reserved.
//

#import "EventDetailStaticTableHeader.h"

@interface EventDetailStaticTableHeader () <UITextFieldDelegate>

@property (weak, nonatomic) IBOutlet UITextField *eventNameTextField;

@property (weak, nonatomic) IBOutlet UITableViewCell *eventNameCell;
@property (weak, nonatomic) IBOutlet UITableViewCell *inviteCodeCell;

@end

@implementation EventDetailStaticTableHeader

- (void)viewDidLoad
{
    self.eventNameTextField.text = self.event.name;
    self.inviteCodeCell.textLabel.text = self.event.uniqueCode;
}


- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath
{
    UITableViewCell *selectedCell = [self.tableView cellForRowAtIndexPath:indexPath];
    if (selectedCell == self.eventNameCell) {
        NSLog(@"event name cell touched");
    } else if (selectedCell == self.inviteCodeCell) {
        NSLog(@"invite code cell touched");
    }
    
    [tableView deselectRowAtIndexPath:indexPath animated:YES];
}

- (BOOL)textFieldShouldReturn:(UITextField *)textField
{
    if([textField.text isEqualToString:@""]) {
        textField.text = [Event createUnique];
    }
    [self.delegate didChangeEventName:textField.text];
    [self.view endEditing:YES];
    return YES;
}

@end
