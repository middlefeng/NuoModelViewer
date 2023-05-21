//
//  ModelSelectionRenderer.m
//  ModelViewer
//
//  Created by Dong on 3/27/18.
//  Updated by Dong on 5/21/23.
//  Copyright © 2023 middleware. All rights reserved.
//

#import "ModelSelectionRenderer.h"
#import "ModelState.h"
#import "NuoMeshSceneRoot.h"
#import "NuoTextureMesh.h"



@implementation ModelSelectionRenderer
{
    // use an immediate target because the selection indicators, which are semi-translucent,
    // should not blend onto themselves (meaning the z-test passed one should overtake the color
    // buffer). but after the indicators are all renderred, the result should be blended onto the
    // scene's render result (through _textureMesh).
    //
    NuoRenderPassTarget* _immediateTarget;
    
    NuoRenderPassTarget* _depthTarget;
    
    NuoTextureMesh* _textureMesh;
}


- (instancetype)initWithCommandQueue:(id<MTLCommandQueue>)commandQueue
                     withPixelFormat:(MTLPixelFormat)pixelFormat
                     withSampleCount:(uint)sampleCount
{
    if ((self = [super initWithCommandQueue:commandQueue withPixelFormat:pixelFormat
                            withSampleCount:sampleCount]))
    {
        _immediateTarget = [[NuoRenderPassTarget alloc] initWithCommandQueue:commandQueue
                                                             withPixelFormat:pixelFormat
                                                             withSampleCount:sampleCount];
        _immediateTarget.name = @"selection - immediate";
        _immediateTarget.manageTargetTexture = YES;
        _immediateTarget.sharedTargetTexture = NO;
        
        _depthTarget = [[NuoRenderPassTarget alloc] initWithCommandQueue:commandQueue
                                                         withPixelFormat:pixelFormat
                                                         withSampleCount:sampleCount];
        _depthTarget.name = @"selection - depth";
        _depthTarget.manageTargetTexture = YES;
        _depthTarget.sharedTargetTexture = NO;
        _depthTarget.resolveDepth = YES;
        _depthTarget.storeDepth = YES;
        
        _textureMesh = [[NuoTextureMesh alloc] initWithCommandQueue:self.commandQueue];
        [_textureMesh makePipelineAndSampler:MTLPixelFormatBGRA8Unorm withBlendMode:kBlend_Alpha];
        
        _enabled = YES;
    }
    
    return self;
}


- (void)setDrawableSize:(CGSize)drawableSize
{
    [super setDrawableSize:drawableSize];
    
    [_immediateTarget setDrawableSize:drawableSize];
    [_depthTarget setDrawableSize:drawableSize];
}


- (id<MTLTexture>)depthMap
{
    return _depthTarget.depthTexture;
}



- (void)predrawWithCommandBuffer:(NuoCommandBuffer *)commandBuffer
{
    {
        const NSUInteger modelSceneSampleCount = [_modelState sceneSampleCount];
        if (modelSceneSampleCount != [_depthTarget sampleCount])
            [_depthTarget setSampleCount:modelSceneSampleCount];
        
        NuoRenderPassEncoder* renderPass = [_depthTarget retainRenderPassEndcoder:commandBuffer];
        
        renderPass.label = @"Selection - depth";
        
        [self setSceneBuffersTo:renderPass];
        [_modelState.sceneRoot drawMesh:renderPass];
        
        [_depthTarget releaseRenderPassEndcoder];
    }
    
    // the above code make this render generate its own depth map so the comments below are
    // obsoleted. immediate rendering happens in the predraw step.
    //
    /* *** below: obsoleted comments
    //
    // the immediate rendering must NOT be put in the predraw because the depth map, which comes from
    // the model renderer, has not been ready (meaning not refreshed for the current frame, still the
    // residual of the last) at that point */
    
    {
        NuoRenderPassEncoder* renderPass = [_immediateTarget retainRenderPassEndcoder:commandBuffer];
        
        renderPass.label = @"Selection - immediate";
        
        if (_enabled)
        {
            // the indicator layer is renderred according to
            //  - the scene parameter
            //  - the scene's depth map (for covering effect)
            //
            [self setSceneBuffersTo:renderPass];
            [self setDepthMapTo:renderPass];
            
            for (NuoMesh* selectedMesh in _modelState.selectedIndicators)
                [selectedMesh drawMesh:renderPass];
        }
        
        [_immediateTarget releaseRenderPassEndcoder];
    }
}



- (void)drawWithCommandBuffer:(NuoCommandBuffer*)commandBuffer
{
    NuoRenderPassEncoder* renderPass = [self retainDefaultEncoder:commandBuffer];
    
    renderPass.label = @"Selection - overlay";
    
    // draw the scene
    [super drawWithCommandBuffer:commandBuffer];
    
    // overlay the selection indicators
    [_textureMesh setModelTexture:_immediateTarget.targetTexture];
    [_textureMesh drawMesh:renderPass];
    
    [self releaseDefaultEncoder];
}


@end
