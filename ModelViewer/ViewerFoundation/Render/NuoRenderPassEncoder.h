//
//  NuoRenderPassEncoder.h
//  ModelViewer
//
//  Created by Dong on 5/3/19.
//  Copyright © 2019 middleware. All rights reserved.
//


#ifndef __NuoRenderPassEncoder_h__
#define __NuoRenderPassEncoder_h__


#import <Foundation/Foundation.h>
#import <Metal/Metal.h>

#import "NuoRenderInFlight.h"


@class NuoBufferSwapChain;


@interface NuoRenderPassEncoder  : NSObject <NuoRenderInFlight>


- (void)setLabel:(NSString*)label;
- (void)setFrontFacingWinding:(MTLWinding)winding;
- (void)setCullMode:(MTLCullMode)cullMode;
- (void)setViewport:(MTLViewport)viewport;

- (void)pushParameterState:(NSString*)name;
- (void)popParameterState;

- (void)setRenderPipelineState:(id<MTLRenderPipelineState>)pipelineState;
- (void)setDepthStencilState:(id<MTLDepthStencilState>)depthStencilState;
- (void)setFragmentSamplerState:(id<MTLSamplerState>)samplerState atIndex:(uint)index;
- (void)setFragmentTexture:(id<MTLTexture>)texture atIndex:(uint)index;
- (void)setFragmentBuffer:(id<MTLBuffer>)buffer offset:(uint)offset atIndex:(uint)index;
- (void)setVertexBuffer:(id<MTLBuffer>)vertexBuffer offset:(uint)offset atIndex:(uint)index;

- (void)setFragmentBufferSwapChain:(NuoBufferSwapChain*)buffer
                            offset:(uint)offset atIndex:(uint)index;
- (void)setVertexBufferSwapChain:(NuoBufferSwapChain*)buffers
                          offset:(uint)offset atIndex:(uint)index;


- (void)drawWithIndices:(id<MTLBuffer>)indexBuffer;
- (void)drawPackedWithIndices:(id<MTLBuffer>)indexBuffer;
- (void)endEncoding;



@end



#endif

