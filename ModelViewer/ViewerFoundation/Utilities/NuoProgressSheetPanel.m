//
//  NuoProgressSheetPanel.m
//  ModelViewer
//
//  Created by Dong on 12/10/17.
//  Copyright © 2017 middleware. All rights reserved.
//

#import "NuoProgressSheetPanel.h"



@implementation NuoProgressSheetPanel
{
    NSProgressIndicator* _indicator;
}


- (instancetype)init
{
    self = [super init];
    if (self)
    {
        [self initControls];
        [self setProgress:0.0];
    }
    
    return self;
}


- (void)initControls
{
    _indicator = [NSProgressIndicator new];
    _indicator.indeterminate = NO;
    
    [self.contentView addSubview:_indicator];
    
    CGRect panelSize = NSMakeRect(0, 0, 340, 120);
    CGRect progressSize = panelSize;
    
    progressSize.size.width -= 50.0;
    progressSize.size.height = 10;
    progressSize.origin.x = (panelSize.size.width - progressSize.size.width) / 2.0;
    progressSize.origin.y = (panelSize.size.height - progressSize.size.height) / 2.0 - 20;
    
    [self setFrame:panelSize display:YES];
    [_indicator setFrame:progressSize];
}


- (void)setProgress:(float)progress
{
    [_indicator setDoubleValue:progress];
}


@end
