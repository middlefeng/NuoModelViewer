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



@interface ModelDirectLighting1 : NSObject

@property (nonatomic, weak) id<MTLTexture> lighting;
@property (nonatomic, weak) id<MTLTexture> blocked;

@end



@interface ModelRayTracingRenderer : NuoRayTracingRenderer


@property (nonatomic, assign) NuoBounds sceneBounds;
@property (nonatomic, assign) NuoRayTracingGlobalIlluminationParam globalIllum;


- (instancetype)initWithCommandQueue:(id<MTLCommandQueue>)commandQueue;

- (void)setLightSource:(NuoLightSource*)lightSource forIndex:(uint)index;
- (id<MTLTexture>)shadowForLightSource:(uint)index withMask:(NuoSceneMask)mask;
- (NSArray<ModelDirectLighting1*>*)directLight;


@end


