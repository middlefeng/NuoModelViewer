//
//  NuoTextureAverageMesh.h
//  ModelViewer
//
//  Created by Dong on 11/11/17.
//  Copyright © 2017 middleware. All rights reserved.
//

#import "NuoScreenSpaceMesh.h"
#import <Metal/Metal.h>


@class NuoRenderPassTarget;
@class NuoCommandBuffer;


@interface NuoTextureAverageMesh : NuoScreenSpaceMesh

- (instancetype)initWithCommandQueue:(id<MTLCommandQueue>)commandQueue;

- (void)makePipelineAndSampler;

- (void)accumulateTexture:(id<MTLTexture>)texture onTarget:(NuoRenderPassTarget*)target
        withCommandBuffer:(NuoCommandBuffer*)commandBuffer;

@end




@interface NuoTextureAccumulator : NSObject

- (instancetype)initWithCommandQueue:(id<MTLCommandQueue>)commandQueue;

- (void)makePipelineAndSampler;

/**
 *  accumulating onto a render target supports the frame buffer only target.
 *  accumulating onto a texture supports only regular texture.
 */
- (void)accumulateTexture:(id<MTLTexture>)texture onTarget:(NuoRenderPassTarget*)target
        withCommandBuffer:(NuoCommandBuffer*)commandBuffer;
- (void)accumulateTexture:(id<MTLTexture>)texture onTexture:(id<MTLTexture>)targetTexture
        withCommandBuffer:(NuoCommandBuffer*)commandBuffer;

@end
