//
//  NuoRenderPassEncoder.m
//  ModelViewer
//
//  Created by Dong on 5/3/19.
//  Copyright © 2019 middleware. All rights reserved.
//

#import "NuoRenderPassEncoder.h"
#import "NuoBufferSwapChain.h"


@implementation NuoRenderPassEncoder
{
    id<MTLRenderCommandEncoder> _encoder;
    uint _inFlight;
}


- (instancetype)initWithEncoder:(id<MTLRenderCommandEncoder>)encoder
              withInFlightIndex:(uint)inFlight
{
    self = [super init];
    
    if (self)
    {
        _encoder = encoder;
        _inFlight = inFlight;
    }
    
    return self;
}


- (void)setLabel:(NSString*)label
{
    [_encoder setLabel:label];
}


- (void)setCullMode:(MTLCullMode)cullMode
{
    [_encoder setCullMode:cullMode];
}


- (void)setFrontFacingWinding:(MTLWinding)winding
{
    [_encoder setFrontFacingWinding:winding];
}


- (void)setViewport:(MTLViewport)viewport
{
    [_encoder setViewport:viewport];
}


- (void)setRenderPipelineState:(id<MTLRenderPipelineState>)pipelineState
{
    [_encoder setRenderPipelineState:pipelineState];
}



- (void)setDepthStencilState:(id<MTLDepthStencilState>)depthStencilState
{
    [_encoder setDepthStencilState:depthStencilState];
}



- (void)setFragmentSamplerState:(id<MTLSamplerState>)samplerState atIndex:(uint)index
{
    [_encoder setFragmentSamplerState:samplerState atIndex:index];
}


- (void)setFragmentTexture:(id<MTLTexture>)texture atIndex:(uint)index
{
    [_encoder setFragmentTexture:texture atIndex:index];
}


- (void)setFragmentBuffer:(id<MTLBuffer>)buffer offset:(uint)offset atIndex:(uint)index
{
    [_encoder setFragmentBuffer:buffer offset:offset atIndex:index];
}


- (void)setVertexBuffer:(id<MTLBuffer>)vertexBuffer offset:(uint)offset atIndex:(uint)index
{
    [_encoder setVertexBuffer:vertexBuffer offset:offset atIndex:index];
}


- (uint)inFlight
{
    return _inFlight;
}


- (void)setFragmentBufferSwapChain:(NuoBufferSwapChain*)buffer
                            offset:(uint)offset atIndex:(uint)index
{
    [self setFragmentBuffer:[buffer bufferForInFlight:self]
                     offset:offset atIndex:index];
}


- (void)setVertexBufferSwapChain:(NuoBufferSwapChain*)buffers
                          offset:(uint)offset atIndex:(uint)index
{
    [self setVertexBuffer:[buffers bufferForInFlight:self]
                   offset:offset atIndex:index];
}



- (void)drawWithIndices:(id<MTLBuffer>)indexBuffer forWide:(BOOL)isWide
{
    size_t count = isWide ? [indexBuffer length] / sizeof(uint32_t) :
                             [indexBuffer length] / sizeof(uint16_t);
    MTLIndexType type = isWide ? MTLIndexTypeUInt32 : MTLIndexTypeUInt16;
    
    [_encoder drawIndexedPrimitives:MTLPrimitiveTypeTriangle
                         indexCount:count indexType:type
                        indexBuffer:indexBuffer indexBufferOffset:0];
}


- (void)drawWithIndices:(id<MTLBuffer>)indexBuffer
{
    [self drawWithIndices:indexBuffer forWide:YES];
}


- (void)drawPackedWithIndices:(id<MTLBuffer>)indexBuffer
{
    [self drawWithIndices:indexBuffer forWide:NO];
}



- (void)endEncoding
{
    [_encoder endEncoding];
    _encoder = nil;
}



@end
