//
//  NuoIlluminationMesh.h
//  ModelViewer
//
//  Created by middleware on 8/27/18.
//  Copyright © 2018 middleware. All rights reserved.
//



#import "NuoTextureMesh.h"

#include "NuoMathVector.h"


@interface NuoIlluminationMesh : NuoTextureMesh

//  all values below are relative to "directLighting" therefore physically based

/**
 *  local light source and ambient
 */
@property (nonatomic, weak) id<MTLTexture> illumination;
@property (nonatomic, weak) id<MTLTexture> illuminationOnVirtual;

/**
 *  direct lighting by the major sources
 */
@property (nonatomic, weak) id<MTLTexture> directLighting;
@property (nonatomic, weak) id<MTLTexture> directLightingWithShadow;

@property (nonatomic, weak) id<MTLTexture> translucentCoverMap;

- (void)setAmbient:(const NuoVectorFloat3&)ambient;

- (void)makePipelineAndSampler:(MTLPixelFormat)pixelFormat
                 withBlendMode:(ScreenSpaceBlendMode)blendMode
                    withHybrid:(BOOL)hybrid;


@end


