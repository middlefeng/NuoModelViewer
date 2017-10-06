//
//  NuoPopoverSheet.m
//  ModelViewer
//
//  Created by dfeng on 10/4/17.
//  Copyright © 2017 middleware. All rights reserved.
//

#import "NuoPopoverSheet.h"



@implementation NuoPopoverSheet



- (instancetype)initWithParent:(NSView*)parent
{
    self = [super init];
    
    if (self)
    {
        self.bezelStyle = NSBezelStyleRoundedDisclosure;
        self.bordered = YES;
        self.title = @"";
        [self setTarget:self];
        [self setAction:@selector(popoverAction:)];
        [parent addSubview:self];
    }
    
    return self;
}


- (void)popoverAction:(id)sender
{
    id<NuoPopoverSheetDelegate> delegate = _sheetDelegate;
    if (!delegate)
        return;
    
    NSPopover* popover = [NSPopover new];
    popover.contentSize = [delegate popoverSheetcontentSize:self];
    popover.behavior = NSPopoverBehaviorTransient;
    _popover = popover;
    
    NSViewController* controller = [delegate popoverSheetcontentViewController:self];
    popover.contentViewController = controller;
    
    [popover showRelativeToRect:[self frame] ofView:self.superview
                  preferredEdge:NSRectEdgeMinY];
}


@end
