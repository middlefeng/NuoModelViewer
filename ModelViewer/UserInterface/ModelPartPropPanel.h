//
//  ModelPartPropPanel.h
//  ModelViewer
//
//  Created by middleware on 1/29/17.
//  Copyright © 2017 middleware. All rights reserved.
//

#import "NuoRoundedView.h"



@class NuoMesh;
@protocol ModelOptionUpdate;



@interface ModelPartPropPanel : NuoRoundedView


@property (nonatomic, weak) id<ModelOptionUpdate> optionUpdateDelegate;


- (void)updateControlsLayout;
- (void)updateForMesh:(NuoMesh*)mesh;
- (void)unhideIfSelected;


@end
