//
//  LightShadowPopoverController.h
//  ModelViewer
//
//  Created by Dong on 9/19/17.
//  Copyright © 2017 middleware. All rights reserved.
//

#import <Cocoa/Cocoa.h>

@class LightOperationPanel;


@interface LightShadowPopoverController : NSViewController

@property (nonatomic, assign) float occluderSearchRadius;

- (instancetype)initWithPopover:(NSPopover*)popover
                withSourcePanel:(LightOperationPanel*)sourcePanel;

@end
