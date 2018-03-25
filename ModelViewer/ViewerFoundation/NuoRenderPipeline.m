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
        
        NuoRenderPipelinePass* renderStepSuccessor = nil;
        
        if (i < [_renderPasses count] - 1)
            renderStepSuccessor = (NuoRenderPipelinePass*)[_renderPasses objectAtIndex:i + 1];
        
        if (renderStepSuccessor)
        {
            NuoRenderPassTarget* interResult = renderStep.renderTarget;
            [renderStepSuccessor setSourceTexture:interResult.targetTexture];
        }
        else
        {
            id<MTLTexture> currentDrawable = [_renderPipelineDelegate nextFinalTexture];
            if (!currentDrawable)
                return NO;
            
            NuoRenderPassTarget* finalResult = renderStep.renderTarget;
            [finalResult setTargetTexture:currentDrawable];
        }
    }
    
    for (size_t i = 0; i < [_renderPasses count]; ++i)
    {
        NuoRenderPass* render = [_renderPasses objectAtIndex:i];
        [render drawWithCommandBuffer:commandBuffer withInFlightIndex:inFlight];
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


- (void)setSampleCount:(NSUInteger)sampleCount
{
    for (size_t i = 0; i < [_renderPasses count]; ++i)
    {
        NuoRenderPass* render = _renderPasses[i];
        [render setSampleCount:sampleCount];
    }
}



@end
