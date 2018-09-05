//
//  NuoAmbientOcclusionRenderer.m
//  ModelViewer
//
//  Created by Dong on 10/1/17.
//  Copyright © 2017 middleware. All rights reserved.
//

#import "NuoDeferredRenderer.h"
#import "NuoScreenSpaceRenderer.h"
#import "NuoScreenSpaceMesh.h"



@implementation NuoDeferredRenderer
{
    NuoScreenSpaceRenderer* _screenSpaceRenderer;
    NuoScreenSpaceMesh* _screenMesh;
    
    id<MTLBuffer> _deferredRenderParamBuffer;
}


- (instancetype)initWithCommandQueue:(id<MTLCommandQueue>)commandQueue
                  withSceneParameter:(id<NuoMeshSceneParametersProvider>)sceneParameter
{
    self = [super init];
    
    if (self)
    {
        self.commandQueue = commandQueue;
        _screenSpaceRenderer = [[NuoScreenSpaceRenderer alloc] initWithCommandQueue:commandQueue withName:@"Screen"];
        _screenSpaceRenderer.paramsProvider = sceneParameter;
        
        _screenMesh = [[NuoScreenSpaceMesh alloc] initWithCommandQueue:commandQueue];
        _screenMesh.sampleCount = 1;
        [_screenMesh makePipelineAndSampler:MTLPixelFormatBGRA8Unorm
                        withFragementShader:@"fragement_deferred"
                              withBlendMode:kBlend_Alpha];
        
        _deferredRenderParamBuffer = [commandQueue.device newBufferWithLength:sizeof(NuoDeferredRenderUniforms)
                                                                      options:MTLResourceOptionCPUCacheModeDefault];
    }
    
    return self;
}


- (id<MTLTexture>)shadowOverlayMap
{
    return [_screenSpaceRenderer shdowOverlayBuffer];
}


- (void)setDrawableSize:(CGSize)drawableSize
{
    [super setDrawableSize:drawableSize];
    [_screenSpaceRenderer setDrawableSize:drawableSize];
}


- (void)setSampleCount:(NSUInteger)sampleCount
{
    [_screenSpaceRenderer setSampleCount:sampleCount];
}


- (void)setRoot:(NuoMeshSceneRoot*)root
{
    [_screenSpaceRenderer setSceneRoot:root];
}


- (void)setParameters:(NuoDeferredRenderUniforms*)params
{
    memcpy(_deferredRenderParamBuffer.contents, params, sizeof(NuoDeferredRenderUniforms));
}


- (void)predrawWithCommandBuffer:(id<MTLCommandBuffer>)commandBuffer withInFlightIndex:(unsigned int)inFlight
{
    [_screenSpaceRenderer drawWithCommandBuffer:commandBuffer withInFlightIndex:inFlight];
}


- (void)drawWithCommandBuffer:(id<MTLCommandBuffer>)commandBuffer withInFlightIndex:(unsigned int)inFlight
{
    id<MTLRenderCommandEncoder> renderPass = [self retainDefaultEncoder:commandBuffer];
    renderPass.label = @"Deferred Render Pass";
    
    [self drawWithRenderPass:renderPass withInFlightIndex:inFlight];
    [self releaseDefaultEncoder];
}


- (void)drawWithRenderPass:(id<MTLRenderCommandEncoder>)renderPass withInFlightIndex:(unsigned int)inFlight
{
    [renderPass setFragmentTexture:_screenSpaceRenderer.positionBuffer atIndex:0];
    [renderPass setFragmentTexture:_screenSpaceRenderer.normalBuffer atIndex:1];
    [renderPass setFragmentTexture:_screenSpaceRenderer.ambientBuffer atIndex:2];
    [renderPass setFragmentTexture:_screenSpaceRenderer.shdowOverlayBuffer atIndex:3];
    [renderPass setFragmentTexture:_immediateResult atIndex:4];
    [renderPass setFragmentBuffer:_deferredRenderParamBuffer offset:0 atIndex:0];
    
    [_screenMesh drawMesh:renderPass indexBuffer:inFlight];
}



@end
