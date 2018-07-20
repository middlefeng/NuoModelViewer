//
//  RayEmittor.m
//  ModelViewer
//
//  Created by middleware on 6/11/18.
//  Copyright © 2018 middleware. All rights reserved.
//

#import "NuoRayEmittor.h"
#import "NuoTypes.h"
#import "NuoComputeEncoder.h"

#include "NuoRandomBuffer.h"
#include "NuoRayTracingUniform.h"

#import <MetalPerformanceShaders/MetalPerformanceShaders.h>


const uint kRayBufferStrid = 36;


@interface NuoRayEmittor()

@property (nonatomic, weak) id<MTLDevice> device;

@end


@implementation NuoRayEmittor
{
    NSArray<id<MTLBuffer>>* _uniformBuffers;
    NSArray<id<MTLBuffer>>* _randomBuffers;
    
    id<MTLBuffer> _rayMaskUniform;
    
    id<MTLComputePipelineState> _pipeline;
    
    id<MTLComputePipelineState> _pipelineMaskOpaque;
    id<MTLComputePipelineState> _pipelineMaskAll;
    
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
            
            uniformBuffer[i].label = @"Ray Uniform";
            randomBuffer[i].label = @"Random";
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



- (void)updateRayMask:(uint32_t)rayMask withCommandBuffer:(id<MTLCommandBuffer>)commandBuffer
         withInFlight:(uint)inFlight
{
    id<MTLComputePipelineState> pipeline;
    if (rayMask | kNuoRayMask_Translucent)
        pipeline = _pipelineMaskAll;
    else
        pipeline = _pipelineMaskOpaque;
    
    NuoComputeEncoder* encoder = [[NuoComputeEncoder alloc] initWithCommandBuffer:commandBuffer
                                                                     withPipeline:pipeline
                                                                         withName:@"Ray Mask"];
    
    [encoder setDataSize:_drawableSize];
    [encoder setBuffer:_uniformBuffers[inFlight] offset:0 atIndex:0];
    [encoder setBuffer:_rayBuffer offset:0 atIndex:1];
    [encoder dispatch];
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
    
    descriptor.computeFunction = [library newFunctionWithName:@"ray_mask_opaque"];
    _pipelineMaskOpaque = [_device newComputePipelineStateWithDescriptor:descriptor options:0 reflection:nil error:&error];
    assert(error == nil);
    
    descriptor.computeFunction = [library newFunctionWithName:@"ray_mask_all"];
    _pipelineMaskAll = [_device newComputePipelineStateWithDescriptor:descriptor options:0 reflection:nil error:&error];
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
    uniform.viewTrans = _viewTrans._m;
    
    memcpy([_uniformBuffers[inFlight] contents], &uniform, sizeof(uniform));
    
    [_uniformBuffers[inFlight] didModifyRange:NSMakeRange(0, sizeof(uniform))];
    
    [self updateRandomBuffer:inFlight];
}


- (id<MTLBuffer>)rayBuffer:(id<MTLCommandBuffer>)commandBuffer withInFlight:(uint)inFlight
{
    [self updateUniform:inFlight];
    
    NuoComputeEncoder* computeEncoder = [[NuoComputeEncoder alloc] initWithCommandBuffer:commandBuffer
                                                                            withPipeline:_pipeline
                                                                                withName:@"Ray Emit"];
    
    [computeEncoder setBuffer:_uniformBuffers[inFlight] offset:0 atIndex:0];
    [computeEncoder setBuffer:_rayBuffer offset:0 atIndex:1];
    [computeEncoder setBuffer:_randomBuffers[inFlight] offset:0  atIndex:2];
    [computeEncoder setDataSize:[self drawableSize]];
    [computeEncoder dispatch];
    
    return _rayBuffer;
}


- (id<MTLBuffer>)uniformBuffer:(uint32_t)inFlight
{
    return _uniformBuffers[inFlight];
}



@end
