//
//  NuoRenderer.m
//  ModelViewer
//
//  Created by middleware on 11/8/16.
//  Copyright © 2016 middleware. All rights reserved.
//

#import "NuoRenderPass.h"


@interface NuoRenderPass()

@end


@implementation NuoRenderPass



- (void)setDrawableSize:(CGSize)drawableSize
{ 
    [_renderTarget setDrawableSize:drawableSize];
}


- (void)predrawWithCommandBuffer:(id<MTLCommandBuffer>)commandBuffer
               withInFlightIndex:(unsigned int)inFlight
{
}


- (void)drawWithCommandBuffer:(id<MTLCommandBuffer>)commandBuffer
            withInFlightIndex:(unsigned int)inFlight
{
}


- (BOOL)isPipelinePass
{
    return NO;
}


@end
