//
//  NuoIlluminationMesh.h
//  ModelViewer
//
//  Created by middleware on 8/27/18.
//  Copyright © 2018 middleware. All rights reserved.
//



#import "NuoTextureMesh.h"



@interface NuoIlluminationMesh : NuoTextureMesh


@property (nonatomic, weak) id<MTLTexture> illuminationMap;
@property (nonatomic, weak) id<MTLTexture> directLighting;
@property (nonatomic, weak) id<MTLTexture> directLightingWithShadow;
@property (nonatomic, weak) id<MTLTexture> shadowOverlayMap;
@property (nonatomic, weak) id<MTLTexture> translucentCoverMap;

- (void)setParameters:(const NuoGlobalIlluminationUniforms&)params;


@end


