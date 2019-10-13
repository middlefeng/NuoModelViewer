//
//  NuoIlluminationMesh.h
//  ModelViewer
//
//  Created by middleware on 8/27/18.
//  Copyright © 2018 middleware. All rights reserved.
//



#import "NuoTextureMesh.h"

#include "NuoMathVector.h"



@interface NuoIlluminationTarget : NSObject


// in full ray tracing,
// values in the textures are relative to "regularLighting" therefore physically based

/**
 *  lighting by regular light sources, e.g. parallel, parellel with cone distribution,
 *  point, area, etc. in full ray tracing, this includes the ambient lighting on normal
 *  surfaces, as well as indirect lighting on virtual surfaces
 *
 *  in hybrid rendering, this is the result of rasterization without ambient
 */
@property (strong, nonatomic) id<MTLTexture> regularLighting;

/**
 *  lighting by ambient and by illumating surfaces on a model, only in hybrid
 */
@property (strong, nonatomic) id<MTLTexture> ambientNormal;

/**
 *  ambient on the first bounce on the virtual surfaces (ground planes), store for
 *  reducing the occlusion to the background
 */
@property (strong, nonatomic) id<MTLTexture> ambientVirtual;
@property (strong, nonatomic) id<MTLTexture> ambientVirtualWithoutBlock;

/**
 *  direct lighting on the virtual surfaces, by regular light sources, e.g. parallel,
 *  parellel with cone distribution, point, area, etc. used for calculate the occlusion
 *  to the background
 */
@property (strong, nonatomic) id<MTLTexture> directVirtual;
@property (strong, nonatomic) id<MTLTexture> directVirtualBlocked;

@property (strong, nonatomic) id<MTLTexture> modelMask;

@end




@interface NuoIlluminationMesh : NuoTextureMesh

@property (nonatomic, weak) NuoIlluminationTarget* illuminations;

@property (nonatomic, weak) id<MTLTexture> translucentCoverMap;

- (void)makePipelineAndSampler:(MTLPixelFormat)pixelFormat
                 withBlendMode:(ScreenSpaceBlendMode)blendMode
                    withHybrid:(BOOL)hybrid;


@end


