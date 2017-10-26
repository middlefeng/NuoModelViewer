//
//  FrameRateView.m
//  ModelViewer
//
//  Created by Dong on 10/25/17.
//  Copyright © 2017 middleware. All rights reserved.
//

#import "FrameRateView.h"


@implementation FrameRateView
{
    NSTextField* _frameRateField;
}


- (void)showFrameRate:(float)frameRate
{
    if (!_frameRateField)
    {
        _frameRateField = [NSTextField new];
        [_frameRateField setEditable:NO];
        [_frameRateField setSelectable:NO];
        [_frameRateField setBordered:NO];
        [_frameRateField setStringValue:@"Field of View:"];
        [_frameRateField setFrame:CGRectMake(10, 5, 100, 18)];
        [self addSubview:_frameRateField];
    }
    
    NSString* fieldString = [[NSString alloc] initWithFormat:@"%0.03f FPS", frameRate];
    [_frameRateField setStringValue:fieldString];
}

@end
