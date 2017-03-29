//
//  NuoMeshCube.h
//  ModelViewer
//
//  Created by dfeng on 3/3/17.
//  Copyright © 2017 middleware. All rights reserved.
//

#import "NuoMesh.h"
#import <simd/simd.h>



@interface NuoCubeMesh : NuoMesh


@property (nonatomic, strong) id<MTLTexture> cubeTexture;

@property (nonatomic, assign) float rotationXDelta;
@property (nonatomic, assign) float rotationYDelta;



- (instancetype)initWithDevice:(id<MTLDevice>)device;

- (void)makePipelineAndSampler:(MTLPixelFormat)pixelFormat;
- (void)setProjectionMatrix:(matrix_float4x4)projection;


@end
