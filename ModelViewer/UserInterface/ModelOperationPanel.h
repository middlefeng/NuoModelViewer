//
//  ModelOperationPanel.h
//  ModelViewer
//
//  Created by middleware on 9/15/16.
//  Copyright © 2016 middleware. All rights reserved.
//

#import "NuoRoundedView.h"
#import "NuoTypes.h"

#import "ModelOptionUpdate.h"



@class NuoMeshOption;
@class NuoMeshAnimation;




@interface ModelOperationPanel : NuoRoundedView


@property (nonatomic, assign) BOOL showModelParts;

@property (nonatomic, strong) NuoMeshOption* meshOptions;

@property (nonatomic, assign) BOOL cullEnabled;

@property (nonatomic, assign) float fieldOfViewRadian;

@property (nonatomic, assign) float ambientDensity;

@property (nonatomic, assign) BOOL showLightSettings;

@property (nonatomic, assign) BOOL brdfMode;

@property (nonatomic, weak) id<ModelOptionUpdate> optionUpdateDelegate;

@property (nonatomic, assign) float animationProgress;


- (void)addSubviews;
- (void)updateControls;
- (void)setModelPartAnimations:(NSArray<NuoMeshAnimation*>*)animations;

@end
