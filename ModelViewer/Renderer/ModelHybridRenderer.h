//
//  ModelRayTracingRenderer.h
//  ModelViewer
//
//  Created by middleware on 8/3/2019.
//  Copyright © 2019 middleware. All rights reserved.
//

#import "NuoRayTracingRenderer.h"
#import "NuoMeshSceneRenderPass.h"


@class NuoLightSource;
@class NuoIlluminationTarget;



@interface ModelDirectLighting : NSObject

@property (nonatomic, weak) id<MTLTexture> lighting;
@property (nonatomic, weak) id<MTLTexture> blocked;

@end



@interface ModelHybridRenderer : NuoRayTracingRenderer


@property (nonatomic, assign) NuoBounds sceneBounds;
@property (nonatomic, assign) NuoRayTracingGlobalIlluminationParam globalIllum;
@property (nonatomic, readonly) NuoIlluminationTarget* rayTracingResult;


- (instancetype)initWithCommandQueue:(id<MTLCommandQueue>)commandQueue;

- (void)setLightSource:(NuoLightSource*)lightSource forIndex:(uint)index;
- (id<MTLTexture>)shadowForLightSource:(uint)index withMask:(NuoSceneMask)mask;
- (NSArray<ModelDirectLighting*>*)directLight;


@end


