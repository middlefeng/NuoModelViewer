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



- (void)performInBackground:(NuoProgressIndicatedFunction)backgroundFunc
                 withWindow:(NSWindow*)rootWindow
             withCompletion:(NuoSimpleFunction)completion
{
    __weak NuoProgressSheetPanel* panel = self;
    __weak NSWindow* window = rootWindow;
    
    [rootWindow beginSheet:panel completionHandler:^(NSModalResponse returnCode) {}];
    
    NuoProgressFunction progressFunc = ^(float progress)
    {
        dispatch_async(dispatch_get_main_queue(), ^
                       { [panel setProgress:progress * 100.0]; });
    };
    
    NuoSimpleFunction backgroundBlock = ^()
    {
        backgroundFunc(progressFunc);
        
        dispatch_sync(dispatch_get_main_queue(), ^
                      {
                          completion();
                          [window endSheet:panel];
                      });
    };
    
    dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), backgroundBlock);
}



@end
