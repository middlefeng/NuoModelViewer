//
//  RayEmittor.m
//  ModelViewer
//
//  Created by Dong on 6/11/18.
//  Updated by Dong on 7/19/23
//  Copyright © 2023 Dong Feng. All rights reserved.
//

#import "NuoPrimaryRayEmitter.h"
#import "NuoTypes.h"
#import "NuoComputeEncoder.h"
#import "NuoCommandBuffer.h"
#import "NuoBufferSwapChain.h"
#import "NuoRayBuffer.h"

#include "NuoRayTracingRandom.h"

#import <MetalPerformanceShaders/MetalPerformanceShaders.h>


@interface NuoPrimaryRayEmitter()

@property (nonatomic, weak) id<MTLDevice> device;

@end


@implementation NuoPrimaryRayEmitter
{
    NuoBufferSwapChain* _uniformBuffers;
    NuoBufferSwapChain* _randomBuffers;
    
    NuoComputePipeline* _pipeline;
    PNuoRayTracingRandom _rng;
}


- (instancetype)initWithCommandQueue:(id<MTLCommandQueue>)commandQueue
{
    self = [super init];
    
    if (self)
    {
        _device = commandQueue.device;
        
        _rng = std::make_shared<NuoRayTracingRandom>(256, 1, 1);
        
        _uniformBuffers = [[NuoBufferSwapChain alloc] initWithDevice:_device
                                                      WithBufferSize:sizeof(NuoRayVolumeUniform)
                                                         withOptions:MTLResourceStorageModeManaged
                                                       withChainSize:kInFlightBufferCount
                                                            withName:@"Ray Emit Transform"];
        _randomBuffers = [[NuoBufferSwapChain alloc] initWithDevice:_device
                                                     WithBufferSize:_rng->BytesSize()
                                                        withOptions:MTLResourceStorageModeManaged
                                                      withChainSize:kInFlightBufferCount
                                                           withName:@"Ray Emit Random"];
        
        [self setupPipeline];
    }
    
    return self;
}



- (void)setupPipeline
{
    // Generates rays according to view/projection matrices
    _pipeline = [[NuoComputePipeline alloc] initWithDevice:_device withFunction:@"primary_ray_emit"];
    _pipeline.name = @"Primary Ray Emit";
}


- (void)updateRandomBuffer:(id<NuoRenderInFlight>)inFlight
{
    id<MTLBuffer> buffer = [_randomBuffers bufferForInFlight:inFlight];
    
    _rng->SetBuffer(buffer.contents);
    _rng->UpdateBuffer();
    [buffer didModifyRange:NSMakeRange(0, _rng->BytesSize())];
}


- (CGPoint)normalizedRange:(const CGSize&)drawableSize
{
    const uint width = (uint)drawableSize.width;
    const uint height = (uint)drawableSize.height;
    
    const float aspectRatio = width / (float)height;
    
    CGPoint result;
    result.y = tan(_fieldOfView / 2.0) * 2.0;
    result.x = result.y * aspectRatio;
    
    return result;
}


- (void)updateUniform:(id<NuoRenderInFlight>)inFlight widthRayBuffer:(NuoRayBuffer*)buffer
{
    const CGSize drawableSize = [buffer dimension];
    
    const uint width = (uint)drawableSize.width;
    const uint height = (uint)drawableSize.height;
    
    NuoRayVolumeUniform uniform;
    
    uniform.wViewPort = width;
    uniform.hViewPort = height;
    
    const CGPoint normalized = [self normalizedRange:drawableSize];
    
    uniform.uRange = normalized.x;
    uniform.vRange = normalized.y;
    uniform.viewTrans = _viewTrans._m;
    
    [_uniformBuffers updateBufferWithInFlight:inFlight withContent:&uniform];
    [self updateRandomBuffer:inFlight];
}


- (void)emitToBuffer:(NuoRayBuffer*)rayBuffer withCommandBuffer:(NuoCommandBuffer*)commandBuffer
{
    [self updateUniform:commandBuffer widthRayBuffer:rayBuffer];
    
    NuoComputeEncoder* computeEncoder = [_pipeline encoderWithCommandBuffer:commandBuffer];
    
    [computeEncoder setBuffer:[_uniformBuffers bufferForInFlight:commandBuffer] offset:0 atIndex:0];
    [computeEncoder setBuffer:rayBuffer.buffer offset:0 atIndex:1];
    [computeEncoder setBuffer:[_randomBuffers  bufferForInFlight:commandBuffer] offset:0  atIndex:2];
    [computeEncoder setDataSize:rayBuffer.dimension];
    [computeEncoder dispatch];
}


- (id<MTLBuffer>)uniformBuffer:(id<NuoRenderInFlight>)inFlight
{
    return [_uniformBuffers bufferForInFlight:inFlight];
}



@end
