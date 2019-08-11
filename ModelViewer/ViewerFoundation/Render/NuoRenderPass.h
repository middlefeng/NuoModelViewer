//
//  NuoRenderer.h
//  ModelViewer
//
//  Created by middleware on 11/8/16.
//  Copyright © 2016 middleware. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <Metal/Metal.h>


#import "NuoRenderPassTarget.h"


@class NuoRenderPassEncoder;
@class NuoCommandBuffer;


@interface NuoRenderPass : NSObject

@property (nonatomic, weak) id<MTLCommandQueue> commandQueue;

@property (nonatomic, strong) NuoRenderPassTarget* renderTarget;


- (void)setDrawableSize:(CGSize)drawableSize;
- (void)setSampleCount:(NSUInteger)sampleCount;

/**
 *  draw calls that target to their own target (e.g. shadow map texture)
 */
- (void)predrawWithCommandBuffer:(NuoCommandBuffer*)commandBuffer;

/**
 *  draw calls that target to the *_renderTarget*
 */
- (void)drawWithCommandBuffer:(NuoCommandBuffer*)commandBuffer;

- (BOOL)isPipelinePass;

- (NuoRenderPassEncoder*)retainDefaultEncoder:(NuoCommandBuffer*)commandBuffer;
- (void)releaseDefaultEncoder;


@end
