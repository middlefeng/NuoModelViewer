//
//  RayEmittor.m
//  ModelViewer
//
//  Created by middleware on 6/11/18.
//  Copyright © 2018 middleware. All rights reserved.
//

#import "NuoPrimaryRayEmitter.h"
#import "NuoTypes.h"
#import "NuoComputeEncoder.h"
#import "NuoRayBuffer.h"

#include "NuoRandomBuffer.h"
#include "NuoRayTracingUniform.h"

#import <MetalPerformanceShaders/MetalPerformanceShaders.h>


@interface NuoPrimaryRayEmitter()

@property (nonatomic, weak) id<MTLDevice> device;

@end


@implementation NuoPrimaryRayEmitter
{
    NSArray<id<MTLBuffer>>* _uniformBuffers;
    NSArray<id<MTLBuffer>>* _randomBuffers;
    
    NuoComputePipeline* _pipeline;
    PRandomGenerator _rng;
}


- (instancetype)initWithCommandQueue:(id<MTLCommandQueue>)commandQueue
{
    self = [super init];
    
    if (self)
    {
        _device = commandQueue.device;
        
        id<MTLBuffer> uniformBuffer[kInFlightBufferCount];
        id<MTLBuffer> randomBuffer[kInFlightBufferCount];
        _rng = std::make_shared<RandomGenerator>(256);
        
        for (uint i = 0; i < kInFlightBufferCount; ++i)
        {
            uniformBuffer[i] = [_device newBufferWithLength:sizeof(NuoRayVolumeUniform)
                                                    options:MTLResourceStorageModeManaged];
            randomBuffer[i] = [_device newBufferWithLength:_rng->BytesSize()
                                                   options:MTLResourceStorageModeManaged];
            
            uniformBuffer[i].label = @"Ray Uniform";
            randomBuffer[i].label = @"Random";
        }
        
        _uniformBuffers = [[NSArray alloc] initWithObjects:uniformBuffer count:kInFlightBufferCount];
        _randomBuffers = [[NSArray alloc] initWithObjects:randomBuffer count:kInFlightBufferCount];
        
        [self setupPipeline];
    }
    
    return self;
}



- (void)setupPipeline
{
    // Generates rays according to view/projection matrices
    _pipeline = [[NuoComputePipeline alloc] initWithDevice:_device withFunction:@"primary_ray_emit"
                                             withParameter:NO];
    _pipeline.name = @"Primary Ray Emit";
}


- (void)updateRandomBuffer:(uint)inFlight
{
    _rng->SetBuffer(_randomBuffers[inFlight].contents);
    _rng->UpdateBuffer();
    [_randomBuffers[inFlight] didModifyRange:NSMakeRange(0, _rng->BytesSize())];
}


- (void)updateUniform:(uint)inFlight widthRayBuffer:(NuoRayBuffer*)buffer
{
    CGSize drawableSize = [buffer dimension];
    
    const uint width = (uint)drawableSize.width;
    const uint height = (uint)drawableSize.height;
    
    NuoRayVolumeUniform uniform;
    
    uniform.wViewPort = width;
    uniform.hViewPort = height;
    
    const float aspectRatio = width / (float)height;
    
    uniform.vRange = tan(_fieldOfView / 2.0) * 2.0;
    uniform.uRange = uniform.vRange * aspectRatio;
    uniform.viewTrans = _viewTrans._m;
    
    memcpy([_uniformBuffers[inFlight] contents], &uniform, sizeof(uniform));
    
    [_uniformBuffers[inFlight] didModifyRange:NSMakeRange(0, sizeof(uniform))];
    
    [self updateRandomBuffer:inFlight];
}


- (void)emitToBuffer:(NuoRayBuffer*)rayBuffer withCommandBuffer:(id<MTLCommandBuffer>)commandBuffer
                                                   withInFlight:(uint)inFlight
{
    [self updateUniform:inFlight widthRayBuffer:rayBuffer];
    
    NuoComputeEncoder* computeEncoder = [_pipeline encoderWithCommandBuffer:commandBuffer];
    
    [computeEncoder setBuffer:_uniformBuffers[inFlight] offset:0 atIndex:0];
    [computeEncoder setBuffer:rayBuffer.buffer offset:0 atIndex:1];
    [computeEncoder setBuffer:_randomBuffers[inFlight] offset:0  atIndex:2];
    [computeEncoder setDataSize:rayBuffer.dimension];
    [computeEncoder dispatch];
}


- (id<MTLBuffer>)uniformBuffer:(uint32_t)inFlight
{
    return _uniformBuffers[inFlight];
}



@end
