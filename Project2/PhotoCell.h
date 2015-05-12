//
//  PhotoCell.h
//  Project2
//
//  Created by Sam Turnbull on 28/02/2015.
//  Copyright (c) 2015 Sam's Software. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "SSCheckMark.h"

@interface PhotoCell : UICollectionViewCell

@property (nonatomic, strong) IBOutlet UIImageView *imageView;
@property (nonatomic, strong) UIImage *photo;
@property (weak, nonatomic) IBOutlet SSCheckMark *checkMarkView;

@end
