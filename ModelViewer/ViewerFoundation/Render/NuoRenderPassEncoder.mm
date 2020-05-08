//
//  NuoRenderPassEncoder.m
//  ModelViewer
//
//  Created by Dong on 5/3/19.
//  Copyright © 2019 middleware. All rights reserved.
//

#import "NuoRenderPassEncoder.h"
#import "NuoBufferSwapChain.h"

#include "NuoRenderParameterState.h"



@implementation NuoRenderPassEncoder
{
    id<MTLRenderCommandEncoder> _encoder;
    uint _inFlight;
    
    NuoRenderPassParameterState _parameterState;
}


/**
 *  protected, used by NuoCommandBuffer only
 */
- (instancetype)initWithEncoder:(id<MTLRenderCommandEncoder>)encoder
              withInFlightIndex:(uint)inFlight
{
    self = [super init];
    
    if (self)
    {
        _encoder = encoder;
        _inFlight = inFlight;
        
        [self pushParameterState:@"Render Pass"];
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


- (void)pushParameterState:(NSString*)name
{
    _parameterState.PushState(name.UTF8String);
}


- (void)popParameterState
{
    _parameterState.PopState();
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
    _parameterState.SetState(index, kNuoParameter_FS);
    
    [_encoder setFragmentSamplerState:samplerState atIndex:index];
}


- (void)setFragmentTexture:(id<MTLTexture>)texture atIndex:(uint)index
{
    _parameterState.SetState(index, kNuoParameter_FT);
    
    [_encoder setFragmentTexture:texture atIndex:index];
}


- (void)setFragmentBuffer:(id<MTLBuffer>)buffer offset:(uint)offset atIndex:(uint)index
{
    _parameterState.SetState(index, kNuoParameter_FB);
    
    [_encoder setFragmentBuffer:buffer offset:offset atIndex:index];
}


- (void)setVertexBuffer:(id<MTLBuffer>)vertexBuffer offset:(uint)offset atIndex:(uint)index
{
    _parameterState.SetState(index, kNuoParameter_VB);
    
    [_encoder setVertexBuffer:vertexBuffer offset:offset atIndex:index];
}


- (uint)inFlight
{
    return _inFlight;
}


- (void)setFragmentBufferInFlight:(NuoBufferInFlight*)buffer
                           offset:(uint)offset atIndex:(uint)index
{
    [self setFragmentBuffer:[buffer bufferForInFlight:self]
                     offset:offset atIndex:index];
}


- (void)setVertexBufferInFlight:(NuoBufferInFlight*)buffers
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
