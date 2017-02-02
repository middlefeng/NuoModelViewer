//
//  ModelPartDimensionPanel.h
//  ModelViewer
//
//  Created by middleware on 2/1/17.
//  Copyright © 2017 middleware. All rights reserved.
//

#import "NuoRoundedView.h"



@class NuoMesh;
@protocol ModelOptionUpdate;



@interface ModelPartDimensionPanel : NuoRoundedView


/**
 *  Called by container view when the container view size changes.
 */
- (void)updateControlsLayout;

/**
 *  Called when the selection in the parts list changes.
 */
- (void)updateForMesh:(NSArray<NuoMesh*>*)mesh;

/**
 *  The prop panel is shown usually only when there is a mesh selected. So
 *  rather than calling setHidden: with NO, a container shall call this method
 *  to have the panel shown according to the context.
 */
- (void)showIfSelected;


@end

