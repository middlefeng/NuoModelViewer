//
//  ModelRayTracerDelegate.h
//  ModelViewer
//
//  Created by Dong on 8/1/19.
//  Copyright © 2019 middleware. All rights reserved.
//

#import "NuoRenderPipelinePass.h"



#import <Foundation/Foundation.h>
#import <Metal/Metal.h>

#import "NuoMeshSceneRenderPass.h"
#import "ModelRenderDelegate.h"
#import "ModelSceneParameters.h"



@class NuoMeshSceneRoot;
@class NuoRayAccelerateStructure;



@interface ModelHybridRenderDelegate : NuoMeshSceneRenderPass < ModelRenderDelegate, ModelShadowMapProvider >


- (instancetype)initWithCommandQueue:(id<MTLCommandQueue>)commandQueue
                     withAccelerator:(NuoRayAccelerateStructure*)accelerateSturcture
                       withSceneRoot:(NuoMeshSceneRoot*)sceneRoot
                 withSceneParameters:(ModelSceneParameters*)sceneParam;


@end

