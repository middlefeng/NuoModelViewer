//
//  NuoComputeEncoder.m
//  ModelViewer
//
//  Created by middleware on 7/8/18.
//  Copyright © 2018 middleware. All rights reserved.
//

#import "NuoComputeEncoder.h"
#import "NuoCommandBuffer.h"



@interface NuoComputeEncoder()

- (void)setComputePipelineState:(id<MTLComputePipelineState>)pipeline;

@end



@implementation NuoComputePipeline
{
    id<MTLComputePipelineState> _pipeline;
}


- (instancetype)initWithDevice:(id<MTLDevice>)device withFunction:(NSString*)function
                 withParameter:(BOOL)param
{
    self = [super init];
    
    if (self)
    {
        id<MTLLibrary> library = [device newDefaultLibrary];
        
        MTLFunctionConstantValues* values = [MTLFunctionConstantValues new];
        [values setConstantValue:&param type:MTLDataTypeBool atIndex:0];
        
        MTLComputePipelineDescriptor *descriptor = [MTLComputePipelineDescriptor new];
        descriptor.threadGroupSizeIsMultipleOfThreadExecutionWidth = YES;
        
        NSError* error;
        descriptor.computeFunction = [library newFunctionWithName:function constantValues:values error:&error];
        assert(error == nil);
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


@end




@implementation NuoComputeEncoder
{
    id<MTLComputeCommandEncoder> _encoder;
}


- (instancetype)initWithCommandBuffer:(id<MTLCommandBuffer>)commandBuffer
                             withName:(NSString*)name
{
    self = [super init];
    
    if (self)
    {
        _encoder = [commandBuffer computeCommandEncoder];
        _encoder.label = name;
        
        _dataSize = CGSizeZero;
    }
    
    return self;
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
    
    [_encoder setTexture:texture atIndex:index];
}


- (void)setSamplerState:(id<MTLSamplerState>)sampler atIndex:(uint)index
{
    [_encoder setSamplerState:sampler atIndex:index];
}



- (void)setBuffer:(id<MTLBuffer>)buffer offset:(uint)offset atIndex:(uint)index
{
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
