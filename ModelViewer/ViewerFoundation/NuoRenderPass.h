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


@interface NuoRenderPass : NSObject

@property (nonatomic, weak) id<MTLCommandQueue> commandQueue;

@property (nonatomic, strong) NuoRenderPassTarget* renderTarget;


- (void)setDrawableSize:(CGSize)drawableSize;
- (void)setSampleCount:(NSUInteger)sampleCount;

/**
 *  draw calls that target to their own target (e.g. shadow map texture)
 */
- (void)predrawWithCommandBuffer:(id<MTLCommandBuffer>)commandBuffer
               withInFlightIndex:(unsigned int)inFlight;

/**
 *  draw calls that target to the *_renderTarget*
 */
- (void)drawWithCommandBuffer:(id<MTLCommandBuffer>)commandBuffer
            withInFlightIndex:(unsigned int)inFlight;

- (BOOL)isPipelinePass;

- (NuoRenderPassEncoder*)retainDefaultEncoder:(id<MTLCommandBuffer>)commandBuffer
                                 withInFlight:(uint)inFlight;
- (void)releaseDefaultEncoder;


@end
