//
//  AllTableViewCell.m
//  Beauteous
//
//  Created by Kenichi Saito on 8/4/15.
//  Copyright (c) 2015 Kenichi Saito. All rights reserved.
//

#import "AllTableViewCell.h"
#import "BOUtility.h"

@implementation AllTableViewCell

/*
// Only override drawRect: if you perform custom drawing.
// An empty implementation adversely affects performance during animation.
- (void)drawRect:(CGRect)rect {
    // Drawing code
}
*/

- (void)awakeFromNib
{
    [super awakeFromNib];
    
    self.contentView.autoresizingMask =
    UIViewAutoresizingFlexibleLeftMargin |
    UIViewAutoresizingFlexibleWidth |
    UIViewAutoresizingFlexibleRightMargin |
    UIViewAutoresizingFlexibleTopMargin |
    UIViewAutoresizingFlexibleHeight |
    UIViewAutoresizingFlexibleBottomMargin;
    
    self.selectionStyle = UITableViewCellSelectionStyleNone;
    self.separatorInset = UIEdgeInsetsMake(0, 8, 0, 0);
    self.layoutMargins = UIEdgeInsetsMake(0, 8, 0, 0);
}

- (instancetype)initWithCoder:(NSCoder *)coder
{
    self = [super initWithCoder:coder];
    if (self) {

    }
    return self;
}

- (void)setDate:(Note *)note
{
    self.titleLabel.text = note.title;
    self.bodyLabel.textColor = [UIColor darkGrayColor];
    self.bodyLabel.attributedText = [self createBodyStringWithNote:note];
}

- (NSMutableAttributedString*)createBodyStringWithNote:(Note*)note
{
    NSDateFormatter *df = [[NSDateFormatter alloc] init];
    df.dateFormat  = @"yyyy/MM/dd";
    
    UIColor *dateColor;
    
    if (note.starred) {
        dateColor = [BOUtility yellowColor];
    } else {
        dateColor = [UIColor blackColor];
    }
    
    NSAttributedString *dateAttrString = [[NSAttributedString alloc] initWithString:[NSString stringWithFormat:@"%@  ", [df stringFromDate:note.updated_at]] attributes:@{NSForegroundColorAttributeName: dateColor, NSFontAttributeName: [UIFont fontWithName:@"Avenir-MediumOblique" size:11]}];
    
    NSMutableAttributedString *bodyAttrString = [[NSMutableAttributedString alloc] initWithString:note.planeString];
    
    NSMutableAttributedString *bodyString = [[NSMutableAttributedString alloc] init];
    [bodyString appendAttributedString:dateAttrString];
    [bodyString appendAttributedString:bodyAttrString];
    
    // NSLog(@"BODY STRING : %@", bodyString);
    
    return bodyString;
}

@end
