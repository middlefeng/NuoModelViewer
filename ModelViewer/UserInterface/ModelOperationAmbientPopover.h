//
//  ModelOperationAmbientPopover.h
//  ModelViewer
//
//  Created by Dong on 10/5/17.
//  Copyright © 2017 middleware. All rights reserved.
//

#import <Cocoa/Cocoa.h>


@class ModelOperationPanel;
@protocol ModelOptionUpdate;


@interface ModelOperationAmbientPopover : NSViewController


- (instancetype)initWithPopover:(NSPopover*)popover
                withSourcePanel:(ModelOperationPanel*)sourcePanel
                   withDelegate:(id<ModelOptionUpdate>)delegate;


@end
