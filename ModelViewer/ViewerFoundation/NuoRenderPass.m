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
{
    id<MTLRenderCommandEncoder> _currentRenderPass;
}


- (id<MTLRenderCommandEncoder>)currentRenderPass:(id<MTLCommandBuffer>)commandBuffer
{
    if (!_currentRenderPass)
    {
        MTLRenderPassDescriptor *passDescriptor = [_renderTarget currentRenderPassDescriptor];
        if (!passDescriptor)
            return nil;
        
        _currentRenderPass = [commandBuffer renderCommandEncoderWithDescriptor:passDescriptor];
    }
    
    return _currentRenderPass;
}


- (void)endCurrentPass
{
    [_currentRenderPass endEncoding];
    _currentRenderPass = nil;
}



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
