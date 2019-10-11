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


//  values in the textures are relative to "directLighting" therefore physically based

@property (strong, nonatomic) id<MTLTexture> regularLighting;
@property (strong, nonatomic) id<MTLTexture> ambientNormal;
@property (strong, nonatomic) id<MTLTexture> ambientVirtual;
@property (strong, nonatomic) id<MTLTexture> ambientVirtualWithoutBlock;
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


