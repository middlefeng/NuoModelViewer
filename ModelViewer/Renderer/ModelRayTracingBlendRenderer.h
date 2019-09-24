//
//  ModelRayTracingBlendRenderer.h
//  ModelViewer
//
//  Created by middleware on 8/27/18.
//  Copyright © 2018 middleware. All rights reserved.
//

#import "NuoRenderPipelinePass.h"
#import "NuoIlluminationMesh.h"



@interface ModelRayTracingBlendRenderer : NuoRenderPass


@property (nonatomic, weak) NuoIlluminationTarget* illuminations;

@property (nonatomic, weak) id<MTLTexture> translucentMap;


- (instancetype)initWithCommandQueue:(id<MTLCommandQueue>)commandQueue
                     withPixelFormat:(MTLPixelFormat)pixelFormat
                     withSampleCount:(uint)sampleCount;


@end


