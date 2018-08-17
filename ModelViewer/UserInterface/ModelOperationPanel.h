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
#import "ModelViewerRenderer.h"



@class NuoMeshOption;
@class NuoMeshAnimation;




@interface ModelOperationPanel : NuoRoundedView


@property (nonatomic, readonly) BOOL showModelParts;
@property (nonatomic, readonly) BOOL showFrameRate;
@property (nonatomic, strong) NSArray<NSString*>* deviceNames;


/**
 *  user-adjustable properties
 */
@property (nonatomic, strong) NSString* deviceSelected;
@property (nonatomic, assign) TransformMode transformMode;
@property (nonatomic, strong) NuoMeshOption* meshOptions;
@property (nonatomic, assign) NuoDeferredRenderUniforms deferredRenderParameters;
@property (nonatomic, assign) BOOL cullEnabled;
@property (nonatomic, assign) float fieldOfViewRadian;
@property (nonatomic, assign) float ambientDensity;
@property (nonatomic, assign) BOOL showLightSettings;
@property (nonatomic, assign) NuoMeshModeShaderParameter meshMode;


@property (nonatomic, weak) id<ModelOptionUpdate> optionUpdateDelegate;

@property (nonatomic, assign) float animationProgress;

@property (nonatomic, assign) RecordStatus motionBlurRecordStatus;
@property (nonatomic, assign) RecordStatus rayTracingRecordStatus;
@property (nonatomic, assign) float illumination;


- (void)addSubviews;
- (void)updateControls;
- (void)setModelPartAnimations:(NSArray<NuoMeshAnimation*>*)animations;

@end
