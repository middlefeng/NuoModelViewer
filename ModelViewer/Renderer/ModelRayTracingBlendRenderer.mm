//
//  ModelRayTracingBlendRenderer.m
//  ModelViewer
//
//  Created by middleware on 8/27/18.
//  Copyright © 2018 middleware. All rights reserved.
//

#import "ModelRayTracingBlendRenderer.h"

#import "NuoComputeEncoder.h"
#import "NuoCommandBuffer.h"
#import "ModelRayTracingRenderer.h"
#import "NuoRenderPassAttachment.h"

#import "NuoInspectableMaster.h"



@implementation ModelRayTracingBlendRenderer
{
    NuoIlluminationMesh* _mesh;
    
    NuoRenderPassTarget* _lightingWithoutBlock;
    NuoRenderPassTarget* _lightingWithBlock;
}


- (instancetype)initWithCommandQueue:(id<MTLCommandQueue>)commandQueue
                     withPixelFormat:(MTLPixelFormat)pixelFormat
                     withSampleCount:(uint)sampleCount
{
    self = [super init];
    
    if (self)
    {
        _mesh = [[NuoIlluminationMesh alloc] initWithCommandQueue:commandQueue];
        
        [_mesh setSampleCount:sampleCount];
        [_mesh makePipelineAndSampler:pixelFormat withBlendMode:kBlend_Alpha
                           withHybrid:NO];
        
        NuoRenderPassTarget* target[2];
        for (uint i = 0; i < 2; ++i)
        {
            target[i] = [[NuoRenderPassTarget alloc] initWithCommandQueue:commandQueue
                                                          withPixelFormat:MTLPixelFormatRGBA32Float
                                                          withSampleCount:1];
            
            NuoRenderPassTarget* current = target[i];
            
            current.manageTargetTexture = YES;
            current.sharedTargetTexture = NO;
            current.clearColor = MTLClearColorMake(0.0, 0.0, 0.0, 1.0);
            current.colorAttachments[0].needWrite = YES;
            current.name = @"Ray Tracing Direct Lighting";
        }
        
        _lightingWithoutBlock = target[0];
        _lightingWithBlock = target[1];
    }
    
    return self;
}


- (void)setAmbient:(const NuoVectorFloat3&)ambient
{
    [_mesh setAmbient:ambient];
}



- (void)setDrawableSize:(CGSize)drawableSize
{
    [_lightingWithoutBlock setDrawableSize:drawableSize];
    [_lightingWithBlock setDrawableSize:drawableSize];
}



- (void)drawWithCommandBuffer:(NuoCommandBuffer*)commandBuffer
{
    NuoRenderPassEncoder* renderPass = [self retainDefaultEncoder:commandBuffer];
    [_mesh setModelTexture:_immediateResult];
    [_mesh setIllumination:_illumination];
    [_mesh setIlluminationOnVirtual:_illuminationOnVirtual];
    [_mesh setDirectLighting:_lightingWithoutBlock.targetTexture];
    [_mesh setDirectLightingWithShadow:_lightingWithBlock.targetTexture];
    [_mesh setTranslucentCoverMap:_translucentMap];
    [_mesh drawMesh:renderPass];
    [self releaseDefaultEncoder];
}

@end
