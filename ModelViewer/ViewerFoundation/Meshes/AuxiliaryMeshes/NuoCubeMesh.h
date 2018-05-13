//
//  NuoMeshCube.h
//  ModelViewer
//
//  Created by dfeng on 3/3/17.
//  Copyright © 2017 middleware. All rights reserved.
//

#import "NuoMesh.h"



@interface NuoCubeMesh : NuoMesh


@property (nonatomic, strong) id<MTLTexture> cubeTexture;

@property (nonatomic, assign) float rotationXDelta;
@property (nonatomic, assign) float rotationYDelta;



- (instancetype)initWithCommandQueue:(id<MTLCommandQueue>)commandQueue;

- (void)makePipelineAndSampler:(MTLPixelFormat)pixelFormat;
- (void)setProjectionMatrix:(const NuoMatrixFloat44&)projection;


@end
