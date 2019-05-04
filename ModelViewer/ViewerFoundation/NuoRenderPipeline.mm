//
//  NuoRenderPipeline.m
//  ModelViewer
//
//  Created by middleware on 2/20/17.
//  Copyright © 2017 middleware. All rights reserved.
//

#import "NuoRenderPipeline.h"
#import "NuoRenderPipelinePass.h"
#import "NuoRenderPassAttachment.h"




@implementation NuoRenderPipeline


- (BOOL)renderWithCommandBuffer:(NuoCommandBuffer*)commandBuffer
{
    for (NuoRenderPass* pass in _renderPasses)
    {
        [pass predrawWithCommandBuffer:commandBuffer];
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
            NuoRenderPassTarget* finalResult = renderStep.renderTarget;
            
            if (!finalResult.manageTargetTexture)
            {
                id<MTLTexture> currentDrawable = [_renderPipelineDelegate nextFinalTexture];
                if (!currentDrawable)
                    return NO;
                
                NuoRenderPassAttachment* attachment = finalResult.colorAttachments[0];
                [attachment setTexture:currentDrawable];
            }
        }
    }
    
    for (size_t i = 0; i < [_renderPasses count]; ++i)
    {
        NuoRenderPass* render = [_renderPasses objectAtIndex:i];
        [render drawWithCommandBuffer:commandBuffer];
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
