//
//  ModelRayTracingRenderer.h
//  ModelViewer
//
//  Created by middleware on 6/22/18.
//  Copyright © 2018 middleware. All rights reserved.
//

#import "NuoRayTracingRenderer.h"
#import "NuoMeshSceneRenderPass.h"


@class NuoLightSource;



enum kModelRayTracingTargets
{
    kModelRayTracingTargets_AmbientNormal = 0,
    kModelRayTracingTargets_AmbientVirtual,
    kModelRayTracingTargets_AmbientVirtualNB,
    kModelRayTracingTargets_Direct,
    kModelRayTracingTargets_DirectVirtual,
    kModelRayTracingTargets_DirectVirtualBlocked
};



@interface ModelRayTracingRenderer : NuoRayTracingRenderer


@property (nonatomic, assign) NuoBounds sceneBounds;
@property (nonatomic, assign) NuoRayTracingGlobalIlluminationParam globalIllum;

@property (nonatomic, strong) NSArray<NuoLightSource*>* lightSources;


- (instancetype)initWithCommandQueue:(id<MTLCommandQueue>)commandQueue;


@end


