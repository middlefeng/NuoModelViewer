//
//  RayEmittor.m
//  ModelViewer
//
//  Created by middleware on 6/11/18.
//  Copyright © 2018 middleware. All rights reserved.
//

#import "NuoRayEmittor.h"
#import "NuoTypes.h"

#include "NuoRandomBuffer.h"
#include "NuoRayTracingUniform.h"


static const uint kRayBufferStrid = 48;


@implementation NuoRayEmittor
{
    NSArray<id<MTLBuffer>>* _uniformBuffers;
    NSArray<id<MTLBuffer>>* _randomBuffers;
    
    id<MTLComputePipelineState> _pipeline;
    
    id<MTLBuffer> _rayBuffer;
}


- (instancetype)initWithCommandQueue:(id<MTLCommandQueue>)commandQueue
{
    self = [super init];
    
    if (self)
    {
        id<MTLDevice> device = commandQueue.device;
        
        id<MTLBuffer> uniformBuffer[kInFlightBufferCount];
        id<MTLBuffer> randomBuffer[kInFlightBufferCount];
        for (uint i = 0; i < kInFlightBufferCount; ++i)
        {
            uniformBuffer[i] = [device newBufferWithLength:sizeof(NuoRayVolumeUniform)
                                                   options:MTLResourceStorageModeManaged];
            randomBuffer[i] = [device newBufferWithLength:sizeof(NuoRayVolumeUniform)
                                                  options:MTLResourceStorageModeManaged];
        }
        
        _uniformBuffers = [[NSArray alloc] initWithObjects:uniformBuffer count:kInFlightBufferCount];
        _randomBuffers = [[NSArray alloc] initWithObjects:randomBuffer count:kInFlightBufferCount];
        
        [self setupPipeline:device];
    }
    
    return self;
}



- (void)setFieldOfView:(CGFloat)fieldOfView
{
    _fieldOfView = fieldOfView;
    _rayBuffer = nil;
}



- (void)setDestineTexture:(id<MTLTexture>)destineTexture
{
    _destineTexture = destineTexture;
    _rayBuffer = nil;
}



- (void)setupPipeline:(id<MTLDevice>)device
{
    NSError* error = nil;
    
    MTLComputePipelineDescriptor *descriptor = [[MTLComputePipelineDescriptor alloc] init];
    descriptor.threadGroupSizeIsMultipleOfThreadExecutionWidth = YES;
    
    // Generates rays according to view/projection matrices
    id<MTLLibrary> library = [device newDefaultLibrary];
    descriptor.computeFunction = [library newFunctionWithName:@"ray_emit"];
    _pipeline = [device newComputePipelineStateWithDescriptor:descriptor options:0 reflection:nil error:&error];
    
    assert(error == nil);
}


- (void)updateRandomBuffer:(uint)inFlight
{
    NuoRandomBuffer<NuoVectorFloat2::_typeTrait::_vectorType> randomBuffer(256);
    memcpy([_randomBuffers[inFlight] contents], randomBuffer.Ptr(), randomBuffer.BytesSize());
        
    [_randomBuffers[inFlight] didModifyRange:NSMakeRange(0, randomBuffer.BytesSize())];
}


- (void)updateUniform:(uint)inFlight
{
    const uint width = (uint)_destineTexture.width;
    const uint height = (uint)_destineTexture.height;
    
    NuoRayVolumeUniform uniform;
    
    uniform.wViewPort = width;
    uniform.hViewPort = height;
    
    const float aspectRatio = width / height;
    
    uniform.uRange = tan(_fieldOfView / 2.0) * 2.0;
    uniform.vRange = uniform.uRange / aspectRatio;
    
    memcpy([_uniformBuffers[inFlight] contents], &uniform, sizeof(uniform));
    
    [_uniformBuffers[inFlight] didModifyRange:NSMakeRange(0, sizeof(uniform))];
    
    [self updateRandomBuffer:inFlight];
}


- (id<MTLBuffer>)rayBuffer:(id<MTLCommandBuffer>)commandBuffer
              withInFlight:(uint)inFlight
{
    [self updateUniform:inFlight];
        
    const uint w = (uint)_destineTexture.width;
    const uint h = (uint)_destineTexture.height;
    uint rayCount = w * h;
    _rayBuffer = [commandBuffer.commandQueue.device newBufferWithLength:(kRayBufferStrid * rayCount)
                                                                options:MTLResourceStorageModePrivate];
    
    MTLSize threads = MTLSizeMake(8, 8, 1);
    MTLSize threadgroups = MTLSizeMake((w + threads.width  - 1) / threads.width,
                                       (h + threads.height - 1) / threads.height, 1);
    
    id<MTLComputeCommandEncoder> computeEncoder = [commandBuffer computeCommandEncoder];
    [computeEncoder setBuffer:_uniformBuffers[inFlight] offset:0 atIndex:0];
    [computeEncoder setBuffer:_rayBuffer offset:0 atIndex:1];
    [computeEncoder setBuffer:_randomBuffers[inFlight] offset:0  atIndex:2];
    [computeEncoder setTexture:_destineTexture atIndex:0];
    
    [computeEncoder setComputePipelineState:_pipeline];
    [computeEncoder dispatchThreadgroups:threadgroups threadsPerThreadgroup:threads];
    
    [computeEncoder endEncoding];
    
    return _rayBuffer;
}



@end
