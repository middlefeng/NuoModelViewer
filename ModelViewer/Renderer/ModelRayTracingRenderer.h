//
//  ModelRayTracingRenderer.h
//  ModelViewer
//
//  Created by middleware on 6/22/18.
//  Copyright © 2018 middleware. All rights reserved.
//

#import "NuoRayTracingRenderer.h"

@class NuoLightSource;



@interface ModelRayTracingRenderer : NuoRayTracingRenderer


@property (nonatomic, assign) NuoBounds sceneBounds;
@property (nonatomic, assign) CGFloat ambientDensity;
@property (nonatomic, assign) CGFloat ambientRadius;
@property (nonatomic, assign) CGFloat illuminationStrength;


- (instancetype)initWithCommandQueue:(id<MTLCommandQueue>)commandQueue;

- (void)setLightSource:(NuoLightSource*)lightSource forIndex:(uint)index;
- (id<MTLTexture>)targetTextureForLightSource:(uint)index
                               forTranslucent:(BOOL)translucent;


@end


