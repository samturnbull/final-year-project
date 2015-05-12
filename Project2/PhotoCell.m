//
//  PhotoCell.m
//  Project
//
//  Created by Sam Turnbull on 28/02/2015.
//  Copyright (c) 2015 Sam's Software. All rights reserved.
//

#import "PhotoCell.h"

@implementation PhotoCell

-(void) setPhoto:(UIImage *)photo {
    
    if(_photo != photo) {
        _photo = photo;
    }
    self.imageView.contentMode = UIViewContentModeScaleAspectFill;
    self.imageView.image = _photo;
}

-(id)initWithCoder:(NSCoder *)aDecoder
{
    self = [super initWithCoder:aDecoder];
    if (self) {
        self.autoresizesSubviews = YES;
        
        SSCheckMark* selectedBGView = [[SSCheckMark alloc] initWithFrame:self.bounds];
        selectedBGView.backgroundColor = [UIColor clearColor];
        selectedBGView.checked = YES;
        self.selectedBackgroundView = selectedBGView;
        [self bringSubviewToFront:self.selectedBackgroundView];
        
        //set size manually to be 30x30 and in bottom right corner
        self.selectedBackgroundView.autoresizingMask = (UIViewAutoresizingFlexibleLeftMargin |
                                                        UIViewAutoresizingFlexibleTopMargin);
        self.selectedBackgroundView.frame = CGRectMake(20.5, 20.5, 30, 30);
    }
    return self;
}

@end
