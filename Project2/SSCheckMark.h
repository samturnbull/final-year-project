//
//  SSCheckMark.h
//  Project2
//
//  Created by Sam Turnbull on 01/04/2015.
//  Copyright (c) 2015 Sam's Software. All rights reserved.
//

#import <UIKit/UIKit.h>

typedef NS_ENUM( NSUInteger, SSCheckMarkStyle )
{
    SSCheckMarkStyleOpenCircle,
    SSCheckMarkStyleGrayedOut
};

@interface SSCheckMark : UIView

@property (readwrite, nonatomic) bool checked;
@property (readwrite, nonatomic) SSCheckMarkStyle checkMarkStyle;

@end