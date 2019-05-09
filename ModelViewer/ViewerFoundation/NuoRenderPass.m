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


- (void)setSampleCount:(NSUInteger)sampleCount
{
    [_renderTarget setSampleCount:sampleCount];
}


- (void)predrawWithCommandBuffer:(NuoCommandBuffer*)commandBuffer
{
}


- (void)drawWithCommandBuffer:(NuoCommandBuffer*)commandBuffer
{
}


- (BOOL)isPipelinePass
{
    return NO;
}


- (NuoRenderPassEncoder*)retainDefaultEncoder:(NuoCommandBuffer*)commandBuffer
{
    return [_renderTarget retainRenderPassEndcoder:commandBuffer];
}


- (void)releaseDefaultEncoder
{
    [_renderTarget releaseRenderPassEndcoder];
}


@end
