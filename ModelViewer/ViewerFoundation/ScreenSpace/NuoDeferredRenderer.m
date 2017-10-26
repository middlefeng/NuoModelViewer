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


- (instancetype)initWithDevice:(id<MTLDevice>)device
            withSceneParameter:(id<NuoMeshSceneParametersProvider>)sceneParameter
{
    self = [super init];
    
    if (self)
    {
        self.device = device;
        _screenSpaceRenderer = [[NuoScreenSpaceRenderer alloc] initWithDevice:device withName:@"Screen"];
        _screenSpaceRenderer.paramsProvider = sceneParameter;
        
        self.renderTarget = [[NuoRenderPassTarget alloc] init];
        self.renderTarget.name = @"deferred";
        self.renderTarget.device = device;
        self.renderTarget.manageTargetTexture = YES;
        self.renderTarget.sharedTargetTexture = YES;
        self.renderTarget.sampleCount = 1;
        
        _screenMesh = [[NuoScreenSpaceMesh alloc] initWithDevice:device];
        [_screenMesh makePipelineAndSampler:MTLPixelFormatBGRA8Unorm
                        withFragementShader:@"fragement_deferred"
                            withSampleCount:1 withAlpha:YES];
        
        _deferredRenderParamBuffer = [self.device newBufferWithLength:sizeof(NuoDeferredRenderUniforms)
                                                              options:MTLResourceOptionCPUCacheModeDefault];
    }
    
    return self;
}


- (void)setDrawableSize:(CGSize)drawableSize
{
    [super setDrawableSize:drawableSize];
    [_screenSpaceRenderer setDrawableSize:drawableSize];
}


- (void)setMeshes:(NSArray<NuoMesh*>*)meshes
{
    [_screenSpaceRenderer setMeshes:meshes];
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
    MTLRenderPassDescriptor *passDescriptor = [self.renderTarget currentRenderPassDescriptor];
    id<MTLRenderCommandEncoder> renderPass = [commandBuffer renderCommandEncoderWithDescriptor:passDescriptor];
    renderPass.label = @"Deferred Render Pass";
    
    [self drawWithRenderPass:renderPass withInFlightIndex:inFlight];
    
    [renderPass endEncoding];
}


- (void)drawWithRenderPass:(id<MTLRenderCommandEncoder>)renderPass withInFlightIndex:(unsigned int)inFlight
{
    [renderPass setFragmentTexture:_screenSpaceRenderer.positionBuffer atIndex:0];
    [renderPass setFragmentTexture:_screenSpaceRenderer.normalBuffer atIndex:1];
    [renderPass setFragmentTexture:_screenSpaceRenderer.ambientBuffer atIndex:2];
    [renderPass setFragmentTexture:_immediateResult atIndex:3];
    [renderPass setFragmentBuffer:_deferredRenderParamBuffer offset:0 atIndex:0];
    
    [_screenMesh drawMesh:renderPass indexBuffer:inFlight];
}



@end
