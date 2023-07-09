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
#import "NuoArgumentBuffer.h"

#include "NuoRenderParameterState.h"



@interface NuoComputeEncoder()

- (void)setComputePipelineState:(id<MTLComputePipelineState>)pipeline;

@end




@implementation NuoComputePipeline
{
    id<MTLComputePipelineState> _pipeline;
    id<MTLFunction> _function;
    __weak id<MTLDevice> _device;
    
    NSString* _functionName;
    MTLFunctionConstantValues* _functionConstants;
}


- (instancetype)initWithDevice:(id<MTLDevice>)device withFunction:(NSString*)function
{
    self = [super init];
    
    if (self)
    {
        _device = device;
        _functionName = function;
        _functionConstants = [MTLFunctionConstantValues new];
    }
    
    return self;
}


- (void)setFunctionConstantBool:(BOOL)value at:(NSUInteger)index
{
    assert(_pipeline == nil);
    
    [_functionConstants setConstantValue:&value type:MTLDataTypeBool atIndex:index];
}


- (void)makePipeline
{
    assert(_pipeline == nil);
    
    NSError* error = nil;
    id<MTLFunction> function = [self pipelineFunction];
    
    MTLComputePipelineDescriptor* descriptor = [MTLComputePipelineDescriptor new];
    descriptor.threadGroupSizeIsMultipleOfThreadExecutionWidth = YES;
    descriptor.computeFunction = function;
    _pipeline = [_device newComputePipelineStateWithDescriptor:descriptor options:0 reflection:nil error:&error];
    assert(error == nil);
}


- (NuoComputeEncoder*)encoderWithCommandBuffer:(NuoCommandBuffer*)commandBuffer
{
    if (!_pipeline)
    {
        [self makePipeline];
    }
    
    NuoComputeEncoder* encoder = [commandBuffer computeEncoderWithName:_name];
    [encoder setComputePipelineState:_pipeline];
    
    return encoder;
}



- (id<MTLFunction>)pipelineFunction
{
    if (!_function)
    {
        id<MTLLibrary> library = [NuoShaderLibrary defaultLibraryWithDevice:_device].library;
        
        NSError* error = nil;
        _function = [library newFunctionWithName:_functionName
                                  constantValues:_functionConstants error:&error];
        assert(error == nil);
    }
    
    return _function;
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
    
    uint _inFlight;
}


/**
 *   internal interface, used by NuoCommandBuffer only
 */
- (instancetype)initWithCommandBuffer:(id<MTLCommandBuffer>)commandBuffer
                             withName:(NSString*)name
                         withInFlight:(uint)inFlight
{
    self = [super init];
    
    if (self)
    {
        _encoder = [commandBuffer computeCommandEncoder];
        _encoder.label = name;
        _inFlight = inFlight;
        
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
    [_encoder useResource:buffer usage:MTLResourceUsageRead | MTLResourceUsageWrite];
}


- (void)setArgumentBuffer:(NuoArgumentBuffer*)buffer
{
    _parameterState.SetState(buffer.index, kNuoParameter_CB);
    
    [_encoder setBuffer:buffer.buffer offset:0 atIndex:buffer.index];
    
    for (NuoArgumentUsage* usage in buffer.argumentsUsage)
        [_encoder useResource:usage.argument usage:usage.usage];
}


- (void)setAccelerateStruct:(id<MTLAccelerationStructure>)acStruct AtIndex:(uint)index
{
    _parameterState.SetState(index, kNuoParameter_CA);
    
    [_encoder setAccelerationStructure:acStruct atBufferIndex:index];
    [_encoder useResource:acStruct usage:MTLResourceUsageRead];
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



- (uint)inFlight
{
    return _inFlight;
}

@end
