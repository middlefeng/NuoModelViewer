//
//  NuoComputeEncoder.m
//  ModelViewer
//
//  Created by Dong on 7/8/18.
//  Updated on 7/9/23.
//  Copyright © 2023. All rights reserved.
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
    NSMutableArray<NSString*>* _intersectionFuncs;
    id<MTLIntersectionFunctionTable> _intersectionFuncTable;
}


@synthesize intersectionFuncTable = _intersectionFuncTable;


- (instancetype)initWithDevice:(id<MTLDevice>)device withFunction:(NSString*)function
{
    self = [super init];
    
    if (self)
    {
        _device = device;
        _functionName = function;
        _functionConstants = [MTLFunctionConstantValues new];
        _intersectionFuncs = [NSMutableArray new];
    }
    
    return self;
}


- (void)reset
{
    _pipeline = nil;
    _intersectionFuncTable = nil;
    _function = nil;
}


- (void)setFunctionConstantBool:(BOOL)value at:(NSUInteger)index
{
    [self reset];
    
    [_functionConstants setConstantValue:&value type:MTLDataTypeBool atIndex:index];
}


- (void)addIntersectionFunction:(NSString*)intersectFunction
{
    [self reset];
    
    [_intersectionFuncs addObject:intersectFunction];
}


- (void)makePipeline
{
    assert(_pipeline == nil);
    
    NSError* error = nil;
    id<MTLFunction> function = [self pipelineFunction];
    MTLLinkedFunctions* linkedFunctions = nil;
           
    auto intersectionFuncs = [self linkedFunctions];
    if (intersectionFuncs.count)
    {
        linkedFunctions = [MTLLinkedFunctions new];
        linkedFunctions.functions = intersectionFuncs;
    }
    
    MTLComputePipelineDescriptor* descriptor = [MTLComputePipelineDescriptor new];
    descriptor.threadGroupSizeIsMultipleOfThreadExecutionWidth = YES;
    descriptor.computeFunction = function;
    descriptor.linkedFunctions = linkedFunctions;
    _pipeline = [_device newComputePipelineStateWithDescriptor:descriptor
                                                       options:0 reflection:nil error:&error];
    assert(error == nil);
    
    if (_intersectionFuncs.count)
    {
        auto desc = [[MTLIntersectionFunctionTableDescriptor alloc] init];
        desc.functionCount = _intersectionFuncs.count;
        
        _intersectionFuncTable = [_pipeline newIntersectionFunctionTableWithDescriptor:desc];
    }
    
    for (uint index = 0; index < intersectionFuncs.count; ++index)
    {
        id <MTLFunctionHandle> handle = [_pipeline functionHandleWithFunction:intersectionFuncs[index]];
        [_intersectionFuncTable setFunction:handle atIndex:index];
    }
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



- (void)setIntersectionResource:(id<MTLBuffer>)resource atIndex:(uint)index
{
    if (!_pipeline)
    {
        [self makePipeline];
    }
    
    [_intersectionFuncTable setBuffer:resource offset:0 atIndex:index];
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


- (NSArray<id<MTLFunction>>*)linkedFunctions
{
    NSMutableArray* result = [NSMutableArray new];
    id<MTLLibrary> library = [NuoShaderLibrary defaultLibraryWithDevice:_device].library;
    
    for (NSString* functionName in _intersectionFuncs)
    {
        id<MTLFunction> function = [library newFunctionWithName:functionName];
        assert(function != nil);
        
        [result addObject:function];
    }

    return result;
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


- (void)setAccelerateStruct:(id<MTLAccelerationStructure>)acStruct atIndex:(uint)index
{
    _parameterState.SetState(index, kNuoParameter_CB);
    
    [_encoder setAccelerationStructure:acStruct atBufferIndex:index];
    [_encoder useResource:acStruct usage:MTLResourceUsageRead];
}


- (void)setIntersectionTable:(id<MTLIntersectionFunctionTable>)table atIndex:(uint)index
{
    _parameterState.SetState(index, kNuoParameter_CB);
    
    [_encoder setIntersectionFunctionTable:table atBufferIndex:index];
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
