//
//  ModelRayTracingBlendRenderer.m
//  ModelViewer
//
//  Created by middleware on 8/3/19.
//  Copyright © 2019 middleware. All rights reserved.
//

#import "ModelHybridBlendRenderer.h"

#import "NuoComputeEncoder.h"
#import "NuoCommandBuffer.h"
#import "ModelHybridRenderer.h"
#import "NuoRenderPassAttachment.h"

#import "NuoInspectableMaster.h"



@implementation ModelHybridBlendRenderer
{
    NuoIlluminationMesh* _mesh;
    
    NuoRenderPassTarget* _lightingWithoutBlock;
    NuoRenderPassTarget* _lightingWithBlock;
    
    NuoComputePipeline* _lightingPipeline;
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
                           withHybrid:YES];
        
        _lightingPipeline = [[NuoComputePipeline alloc] initWithDevice:commandQueue.device
                                                          withFunction:@"lighting_accumulate"];
        
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


- (void)setDrawableSize:(CGSize)drawableSize
{
    [_lightingWithoutBlock setDrawableSize:drawableSize];
    [_lightingWithBlock setDrawableSize:drawableSize];
}



- (void)predrawWithCommandBuffer:(NuoCommandBuffer *)commandBuffer
{
    NuoComputeEncoder* encoder = [_lightingPipeline encoderWithCommandBuffer:commandBuffer];
    
    //
    //
    [encoder setTexture:_directLighting[0].lighting atIndex:0];
    [encoder setTexture:_directLighting[1].lighting atIndex:1];
    [encoder setTexture:_directLighting[0].blocked atIndex:2];
    [encoder setTexture:_directLighting[1].blocked atIndex:3];
    
    [encoder setTexture:_lightingWithoutBlock.targetTexture atIndex:4];
    [encoder setTexture:_lightingWithBlock.targetTexture atIndex:5];
    [encoder dispatch];
    
    NuoInspectableMaster* inspectMaster = [NuoInspectableMaster sharedMaster];
    [inspectMaster updateTexture:_lightingWithBlock.targetTexture
                         forName:kInspectable_DirectLightWithShadow];
}



- (void)drawWithCommandBuffer:(NuoCommandBuffer*)commandBuffer
{
    _illuminations.directVirtual = _lightingWithoutBlock.targetTexture;
    _illuminations.directVirtualBlocked = _lightingWithBlock.targetTexture;
    
    NuoRenderPassEncoder* renderPass = [self retainDefaultEncoder:commandBuffer];
    [_mesh setIlluminations:_illuminations];
    [_mesh setTranslucentCoverMap:_translucentMap];
    [_mesh drawMesh:renderPass];
    [self releaseDefaultEncoder];
}

@end
