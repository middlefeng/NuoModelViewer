//
//  NuoRenderPipeline.m
//  ModelViewer
//
//  Created by middleware on 2/20/17.
//  Copyright © 2017 middleware. All rights reserved.
//

#import "NuoRenderPipeline.h"
#import "NuoRenderPipelinePass.h"




@implementation NuoRenderPipeline


- (BOOL)renderWithCommandBuffer:(id<MTLCommandBuffer>)commandBuffer
                       inFlight:(uint)inFlight
{
    for (NuoRenderPass* pass in _renderPasses)
    {
        [pass predrawWithCommandBuffer:commandBuffer withInFlightIndex:inFlight];
    }
    
    for (size_t i = 0; i < [_renderPasses count]; ++i)
    {
        NuoRenderPass* renderStep = [_renderPasses objectAtIndex:i];
        if (!renderStep.isPipelinePass)
            continue;
        
        NuoRenderPipelinePass* render1 = (NuoRenderPipelinePass*)renderStep;
        NuoRenderPipelinePass* render2 = nil;
        
        if (i < [_renderPasses count] - 1)
            render2 = (NuoRenderPipelinePass*)[_renderPasses objectAtIndex:i + 1];
        
        if (render2)
        {
            NuoRenderPassTarget* interResult = render1.renderTarget;
            [render2 setSourceTexture:interResult.targetTexture];
        }
        else
        {
            id<MTLTexture> currentDrawable = [_renderPipelineDelegate nextFinalTexture];
            if (!currentDrawable)
                return NO;
            
            NuoRenderPassTarget* finalResult = render1.renderTarget;
            [finalResult setTargetTexture:currentDrawable];
        }
    }
    
    for (size_t i = 0; i < [_renderPasses count]; ++i)
    {
        NuoRenderPass* render = [_renderPasses objectAtIndex:i];
        [render drawWithCommandBuffer:commandBuffer withInFlightIndex:inFlight];
        [render endCurrentPass];
    }
    
    return YES;
}


- (void)setDrawableSize:(CGSize)size
{
    for (size_t i = 0; i < [_renderPasses count]; ++i)
    {
        NuoRenderPass* render = _renderPasses[i];
        [render setDrawableSize:size];
    }
}


@end
