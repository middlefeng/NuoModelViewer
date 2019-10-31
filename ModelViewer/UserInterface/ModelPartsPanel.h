//
//  ModelPartsList.h
//  ModelViewer
//
//  Created by middleware on 1/7/17.
//  Copyright © 2017 middleware. All rights reserved.
//

#import <Cocoa/Cocoa.h>


@class ModelState;
@protocol ModelOptionUpdate;
@protocol ModelPanelUpdate;



@interface ModelPartsPanel : NSView


/**
 *  delegate responsible for updating the model (managed by model renderer)
 */
@property (nonatomic, weak) id<ModelOptionUpdate> optionUpdateDelegate;

/**
 *  delegate responsible for updating the UI when the state of the parts
 *  list changed (e.g. selection change).
 */
@property (nonatomic, weak) id<ModelPanelUpdate> panelUpdateDelegate;

@property (nonatomic, weak) ModelState* modelState;


- (void)updatePartsPanelWithReload:(BOOL)reload;


@end
