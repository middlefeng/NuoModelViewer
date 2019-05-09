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
    // rendering that do not need the drawable (which is subject to the limit of
    // the render surface frame buffers, therefore might cause wait)
    //
    for (NuoRenderPass* pass : _renderPasses)
    {
        [pass predrawWithCommandBuffer:commandBuffer];
    }
    
    // associate the source and destine texture of each step, along the course
    // of rendering each step
    //
    const size_t count = [_renderPasses count];
    for (size_t i = 0; i < count; ++i)
    {
        const NuoRenderPass* renderStep = [_renderPasses objectAtIndex:i];
        if (!renderStep.isPipelinePass)
            continue;
        
        NuoRenderPipelinePass* renderStepSuccessor = nil;
        
        if (i < count - 1)
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
                // request the drawable only when it is immediately needed
                //
                id<MTLTexture> currentDrawable = [_renderPipelineDelegate nextFinalTexture];
                if (!currentDrawable)
                    return NO;
                
                NuoRenderPassAttachment* attachment = finalResult.colorAttachments[0];
                [attachment setTexture:currentDrawable];
            }
        }
        
        [renderStep drawWithCommandBuffer:commandBuffer];
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
