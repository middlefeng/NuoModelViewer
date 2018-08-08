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



const uint kRayBufferStrid = 36;



@interface NuoRayBuffer()

@property (nonatomic, weak) id<MTLDevice> device;

@end



@implementation NuoRayBuffer
{
    NuoComputePipeline* _pipelineMaskOpaque;
    NuoComputePipeline* _pipelineMaskTranslucent;
    NuoComputePipeline* _pipelineMaskIllum;
}



- (instancetype)initWithDevice:(id<MTLDevice>)device
{
    self = [super init];
    
    if (self)
    {
        _device = device;
        [self setupPipeline];
    }
    
    return self;
}


- (void)setupPipeline
{
    _pipelineMaskOpaque = [[NuoComputePipeline alloc] initWithDevice:_device withFunction:@"ray_set_mask" withParameter:NO];
    _pipelineMaskTranslucent = [[NuoComputePipeline alloc] initWithDevice:_device withFunction:@"ray_set_mask" withParameter:YES];
    
    _pipelineMaskIllum = [[NuoComputePipeline alloc] initWithDevice:_device
                                                       withFunction:@"ray_set_mask_illuminating"
                                                      withParameter:NO];
    
    _pipelineMaskOpaque.name = @"Ray Mask (Opaque)";
    _pipelineMaskTranslucent.name = @"Ray Mask (Translucent)";
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
    const uint rayBufferSize = kRayBufferStrid * rayCount;
    _buffer = [_device newBufferWithLength:rayBufferSize options:MTLResourceStorageModePrivate];
}



- (void)updateRayMask:(uint32_t)rayMask withUniform:(id<MTLBuffer>)uniforms
                                  withCommandBuffer:(id<MTLCommandBuffer>)commandBuffer
{
    NuoComputePipeline* pipeline;
    if (rayMask & kNuoRayMask_Illuminating)
        pipeline = _pipelineMaskIllum;
    else if (rayMask & kNuoRayMask_Translucent)
        pipeline = _pipelineMaskTranslucent;
    else
        pipeline = _pipelineMaskOpaque;
    
    NuoComputeEncoder* encoder = [pipeline encoderWithCommandBuffer:commandBuffer];
    
    [encoder setDataSize:_dimension];
    [encoder setBuffer:uniforms offset:0 atIndex:0];
    [encoder setBuffer:_buffer offset:0 atIndex:1];
    [encoder dispatch];
}


@end
