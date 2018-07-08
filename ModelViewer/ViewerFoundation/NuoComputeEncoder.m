//
//  NuoComputeEncoder.m
//  ModelViewer
//
//  Created by middleware on 7/8/18.
//  Copyright © 2018 middleware. All rights reserved.
//

#import "NuoComputeEncoder.h"


@implementation NuoComputeEncoder
{
    id<MTLComputeCommandEncoder> _encoder;
}


- (instancetype)initWithCommandBuffer:(id<MTLCommandBuffer>)commandBuffer
                         withPipeline:(id<MTLComputePipelineState>)pipeline
{
    self = [super init];
    
    if (self)
    {
        _encoder = [commandBuffer computeCommandEncoder];
        [_encoder setComputePipelineState:pipeline];
        
        _dataSize = CGSizeZero;
    }
    
    return self;
}



- (void)setTexture:(id<MTLTexture>)texture atIndex:(uint)index
{
    CGSize textureSize = CGSizeMake(texture.width, texture.height);
    assert(CGSizeEqualToSize(textureSize, _dataSize) || CGSizeEqualToSize(_dataSize, CGSizeZero));
    
    _dataSize = textureSize;
    
    [_encoder setTexture:texture atIndex:index];
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
