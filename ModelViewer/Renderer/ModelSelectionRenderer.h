//
//  ModelSelectionRenderer.h
//  ModelViewer
//
//  Created by Dong on 3/27/18.
//  Copyright © 2018 middleware. All rights reserved.
//

#import "NuoMeshSceneRenderPass.h"

@class NuoMesh;
@class ModelState;


@interface ModelSelectionRenderer : NuoMeshSceneRenderPass

@property (nonatomic, assign) BOOL enabled;
@property (nonatomic, weak) ModelState* modelState;

@end
