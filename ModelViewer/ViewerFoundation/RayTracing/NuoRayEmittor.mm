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

#import <MetalPerformanceShaders/MetalPerformanceShaders.h>


const uint kRayBufferStrid = 48;


@interface NuoRayEmittor()

@property (nonatomic, weak) id<MTLDevice> device;

@end


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
        _device = commandQueue.device;
        
        id<MTLBuffer> uniformBuffer[kInFlightBufferCount];
        id<MTLBuffer> randomBuffer[kInFlightBufferCount];
        NuoRandomBuffer<NuoVectorFloat2::_typeTrait::_vectorType> randomBufferContent(256);
        
        for (uint i = 0; i < kInFlightBufferCount; ++i)
        {
            uniformBuffer[i] = [_device newBufferWithLength:sizeof(NuoRayVolumeUniform)
                                                    options:MTLResourceStorageModeManaged];
            randomBuffer[i] = [_device newBufferWithLength:randomBufferContent.BytesSize()
                                                   options:MTLResourceStorageModeManaged];
        }
        
        _uniformBuffers = [[NSArray alloc] initWithObjects:uniformBuffer count:kInFlightBufferCount];
        _randomBuffers = [[NSArray alloc] initWithObjects:randomBuffer count:kInFlightBufferCount];
        
        [self setupPipeline];
    }
    
    return self;
}



- (void)setFieldOfView:(CGFloat)fieldOfView
{
    _fieldOfView = fieldOfView;
}



- (uint)rayCount
{
    CGSize drawableSize = [self drawableSize];
    
    const uint w = (uint)drawableSize.width;
    const uint h = (uint)drawableSize.height;
    
    return w * h;
}



- (void)setDrawableSize:(CGSize)drawableSize
{
    _drawableSize = drawableSize;
    
    const uint rayCount = [self rayCount];
    const uint rayBufferSize = kRayBufferStrid * rayCount;
    _rayBuffer = [_device newBufferWithLength:rayBufferSize options:MTLResourceStorageModePrivate];
}



- (void)setupPipeline
{
    NSError* error = nil;
    
    MTLComputePipelineDescriptor *descriptor = [[MTLComputePipelineDescriptor alloc] init];
    descriptor.threadGroupSizeIsMultipleOfThreadExecutionWidth = YES;
    
    // Generates rays according to view/projection matrices
    id<MTLLibrary> library = [_device newDefaultLibrary];
    descriptor.computeFunction = [library newFunctionWithName:@"ray_emit"];
    _pipeline = [_device newComputePipelineStateWithDescriptor:descriptor options:0 reflection:nil error:&error];
    
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
    CGSize drawableSize = [self drawableSize];
    
    const uint width = (uint)drawableSize.width;
    const uint height = (uint)drawableSize.height;
    
    NuoRayVolumeUniform uniform;
    
    uniform.wViewPort = width;
    uniform.hViewPort = height;
    
    const float aspectRatio = width / (float)height;
    
    uniform.vRange = tan(_fieldOfView / 2.0) * 2.0;
    uniform.uRange = uniform.vRange * aspectRatio;
    
    memcpy([_uniformBuffers[inFlight] contents], &uniform, sizeof(uniform));
    
    [_uniformBuffers[inFlight] didModifyRange:NSMakeRange(0, sizeof(uniform))];
    
    [self updateRandomBuffer:inFlight];
}


- (id<MTLBuffer>)rayBuffer:(id<MTLCommandBuffer>)commandBuffer
              withInFlight:(uint)inFlight
                  toTarget:(NuoRenderPassTarget*)renderTarget
{
    [self updateUniform:inFlight];
    
    CGSize drawableSize = [self drawableSize];
    const float w = drawableSize.width;
    const float h = drawableSize.height;
    
    MTLSize threads = MTLSizeMake(8, 8, 1);
    MTLSize threadgroups = MTLSizeMake((w + threads.width  - 1) / threads.width,
                                       (h + threads.height - 1) / threads.height, 1);
    
    id<MTLComputeCommandEncoder> computeEncoder = [commandBuffer computeCommandEncoder];
    [computeEncoder setBuffer:_uniformBuffers[inFlight] offset:0 atIndex:0];
    [computeEncoder setBuffer:_rayBuffer offset:0 atIndex:1];
    [computeEncoder setBuffer:_randomBuffers[inFlight] offset:0  atIndex:2];
    [computeEncoder setTexture:renderTarget.targetTexture atIndex:0];
    
    [computeEncoder setComputePipelineState:_pipeline];
    [computeEncoder dispatchThreadgroups:threadgroups threadsPerThreadgroup:threads];
    
    [computeEncoder endEncoding];
    
    return _rayBuffer;
}


- (id<MTLBuffer>)uniformBuffer:(uint32_t)inFlight
{
    return _uniformBuffers[inFlight];
}



@end
