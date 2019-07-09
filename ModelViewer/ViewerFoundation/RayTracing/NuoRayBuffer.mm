//
//  NuoRayBuffer.m
//  ModelViewer
//
//  Created by middleware on 7/20/18.
//  Copyright © 2018 middleware. All rights reserved.
//

#import "NuoRayBuffer.h"
#import "NuoComputeEncoder.h"
#import "NuoRayTracingUniform.h"



const uint kRayBufferStride = 56;  //  base fields           - 32
                                   //  path scatter          - 12
                                   //  bounce                - 4
                                   //  primary hit mask      - 4
                                   //  ambient illuminateed  - 4



@interface NuoRayBuffer()

@property (nonatomic, weak) id<MTLCommandQueue> commandQueue;

@end



@implementation NuoRayBuffer
{
    NuoComputePipeline* _pipeline;
    id<MTLBuffer> _pipelineMask;
}



- (instancetype)initWithCommandQueue:(id<MTLCommandQueue>)commandQueue;
{
    self = [super init];
    
    if (self)
    {
        _commandQueue = commandQueue;
        [self setupPipeline];
    }
    
    return self;
}


- (void)setupPipeline
{
    id<MTLDevice> device = _commandQueue.device;
    
    uint32 pipelineMask[] = { kNuoRayMask_Opaue | kNuoRayIndex_OnVirtual,
                              kNuoRayMask_Opaue | kNuoRayIndex_OnVirtual | kNuoRayMask_Translucent,
                              kNuoRayMask_Virtual,
                              kNuoRayMask_Illuminating };
    
    id<MTLBuffer> mask = [device newBufferWithBytes:&pipelineMask length:sizeof(pipelineMask)
                                             options:MTLResourceStorageModeShared];
    
    _pipelineMask = [device newBufferWithLength:sizeof(pipelineMask)
                                        options:MTLResourceStorageModePrivate];
    
    id<MTLCommandBuffer> commandBuffer = [self.commandQueue commandBuffer];
    id<MTLBlitCommandEncoder> encoder = [commandBuffer blitCommandEncoder];
    [encoder copyFromBuffer:mask sourceOffset:0 toBuffer:_pipelineMask destinationOffset:0 size:sizeof(pipelineMask)];
    [encoder endEncoding];
    [commandBuffer commit];
    
    _pipeline = [[NuoComputePipeline alloc] initWithDevice:device withFunction:@"ray_set_mask"];
    _pipeline.name = @"Ray Mask";
}


- (uint)rayCount
{
    const uint w = (uint)_dimension.width;
    const uint h = (uint)_dimension.height;
    
    return w * h;
}


- (void)setDimension:(CGSize)dimension
{
    _dimension = dimension;
    
    const uint rayCount = [self rayCount];
    const uint rayBufferSize = kRayBufferStride * rayCount;
    
    _buffer = [_commandQueue.device newBufferWithLength:rayBufferSize options:MTLResourceStorageModePrivate];
}



- (void)updateMask:(uint32_t)rayMaskSet withUniform:(id<MTLBuffer>)uniforms
                               withCommandBuffer:(NuoCommandBuffer*)commandBuffer
{
    NuoComputeEncoder* encoder = [_pipeline encoderWithCommandBuffer:commandBuffer];
    
    [encoder setDataSize:_dimension];
    [encoder setBuffer:uniforms offset:0 atIndex:0];
    [encoder setBuffer:_pipelineMask offset:rayMaskSet * sizeof(uint32) atIndex:1];
    [encoder setBuffer:_buffer offset:0 atIndex:2];
    [encoder dispatch];
}


@end
