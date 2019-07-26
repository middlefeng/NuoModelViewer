//
//  ModelHybridRenderDelegate.h
//  ModelViewer
//
//  Created by Dong on 7/22/19.
//  Copyright © 2019 middleware. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <Metal/Metal.h>

#import "NuoMeshSceneRenderPass.h"
#import "ModelRenderDelegate.h"



@class NuoMeshSceneRoot;
@class NuoRayAccelerateStructure;



@interface ModelHybridRenderDelegate : NuoMeshSceneRenderPass < ModelRenderDelegate >


- (instancetype)initWithCommandQueue:(id<MTLCommandQueue>)commandQueue
                     withAccelerator:(NuoRayAccelerateStructure*)accelerateSturcture
                       withSceneRoot:(NuoMeshSceneRoot*)sceneRoot
                 withSceneParameters:(id<NuoMeshSceneParametersProvider>)sceneParam;


@end


