//
//  NuoComputeEncoder.m
//  ModelViewer
//
//  Created by middleware on 7/8/18.
//  Copyright © 2018 middleware. All rights reserved.
//

#import "NuoComputeEncoder.h"
#import "NuoCommandBuffer.h"
#import "NuoShaderLibrary.h"

#include "NuoRenderParameterState.h"



@interface NuoComputeEncoder()

- (void)setComputePipelineState:(id<MTLComputePipelineState>)pipeline;

@end




@implementation NuoComputePipeline
{
    id<MTLComputePipelineState> _pipeline;
    id<MTLFunction> _function;
}


- (instancetype)initWithDevice:(id<MTLDevice>)device withFunction:(NSString*)function
{
    self = [super init];
    
    if (self)
    {
        id<MTLLibrary> library = [NuoShaderLibrary defaultLibraryWithDevice:device].library;
        
        MTLFunctionConstantValues* values = [MTLFunctionConstantValues new];
        MTLComputePipelineDescriptor *descriptor = [MTLComputePipelineDescriptor new];
        descriptor.threadGroupSizeIsMultipleOfThreadExecutionWidth = YES;
        
        NSError* error;
        _function = [library newFunctionWithName:function constantValues:values error:&error];
        assert(error == nil);
        
        descriptor.computeFunction = _function;
        _pipeline = [device newComputePipelineStateWithDescriptor:descriptor options:0 reflection:nil error:&error];
        assert(error == nil);
    }
    
    return self;
}


- (NuoComputeEncoder*)encoderWithCommandBuffer:(NuoCommandBuffer*)commandBuffer
{
    NuoComputeEncoder* encoder = [commandBuffer computeEncoderWithName:_name];
    [encoder setComputePipelineState:_pipeline];
    
    return encoder;
}


- (id<MTLArgumentEncoder>)argumentEncoder:(NSUInteger)index
{
    return [_function newArgumentEncoderWithBufferIndex:index];
}


@end




@implementation NuoComputeEncoder
{
    id<MTLComputeCommandEncoder> _encoder;
    NuoRenderPassParameterState _parameterState;
}


/**
 *   internal interface, used by NuoCommandBuffer only
 */
- (instancetype)initWithCommandBuffer:(id<MTLCommandBuffer>)commandBuffer
                             withName:(NSString*)name
{
    self = [super init];
    
    if (self)
    {
        _encoder = [commandBuffer computeCommandEncoder];
        _encoder.label = name;
        
        _dataSize = CGSizeZero;
        
        [self pushParameterState:@"Compute Pass"];
    }
    
    return self;
}


- (void)pushParameterState:(NSString*)name
{
    _parameterState.PushState(name.UTF8String);
}


- (void)popParameterState
{
    _parameterState.PopState();
}



- (void)setComputePipelineState:(id<MTLComputePipelineState>)pipeline
{
    [_encoder setComputePipelineState:pipeline];
}



- (void)setTargetTexture:(id<MTLTexture>)texture atIndex:(uint)index
{
#if DEBUG
    CGSize textureSize = CGSizeMake(texture.width, texture.height);
    assert(CGSizeEqualToSize(textureSize, _dataSize) || CGSizeEqualToSize(_dataSize, CGSizeZero));
#endif
    
    [self setTexture:texture atIndex:index];
}



- (void)setTexture:(id<MTLTexture>)texture atIndex:(uint)index
{
    CGSize textureSize = CGSizeMake(texture.width, texture.height);
    _dataSize = textureSize;
    
    _parameterState.SetState(index, kNuoParameter_CT);
    
    [_encoder setTexture:texture atIndex:index];
}


- (void)setSamplerState:(id<MTLSamplerState>)sampler atIndex:(uint)index
{
    _parameterState.SetState(index, kNuoParameter_CS);
    
    [_encoder setSamplerState:sampler atIndex:index];
}



- (void)setBuffer:(id<MTLBuffer>)buffer offset:(uint)offset atIndex:(uint)index
{
    _parameterState.SetState(index, kNuoParameter_CB);
    
    [_encoder setBuffer:buffer offset:offset atIndex:index];
}


- (void)dispatch
{
    const float w = _dataSize.width;
    const float h = _dataSize.height;
    MTLSize threads = MTLSizeMake(8, 8, 1);
    MTLSize threadgroups = MTLSizeMake((w + threads.width  - 1) / threads.width,
                                       (h + threads.height - 1) / threads.height, 1);
    
    [_encoder dispatchThreadgroups:threadgroups threadsPerThreadgroup:threads];
    [_encoder endEncoding];
}



@end
