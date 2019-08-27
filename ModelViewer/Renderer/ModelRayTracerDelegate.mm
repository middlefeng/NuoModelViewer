//
//  ModelRayTracerDelegate.m
//  ModelViewer
//
//  Created by Dong on 8/1/19.
//  Copyright © 2019 middleware. All rights reserved.
//

#import "ModelRayTracerDelegate.h"

#import "NuoBufferSwapChain.h"
#import "NuoLightSource.h"
#import "NuoShadowMapRenderer.h"
#import "NuoDeferredRenderer.h"
#import "ModelRayTracingRenderer.h"
#import "ModelRayTracingBlendRenderer.h"
#import "NuoInspectableMaster.h"

#include "NuoMeshSceneRoot.h"



@implementation ModelRayTracerDelegate
{
    NuoShadowMapRenderer* _shadowMapRenderer[2];
    NuoRenderPassTarget* _immediateTarget;
    ModelRayTracingBlendRenderer* _illuminationRenderer;
    
    ModelRayTracingRenderer* _rayTracingRenderer;
    
    NuoVectorFloat3 _ambient;
    NuoAmbientUniformField _ambientParameters;
    
    __weak NuoMeshSceneRoot* _sceneRoot;
    __weak NuoRenderPassTarget* _delegateTarget;
}


@synthesize fieldOfView;
@synthesize viewMatrix;
@synthesize illuminationStrength;
@synthesize rayTracingRecordStatus = _rayTracingRecordStatus;
@synthesize lights;
@synthesize lightCastBuffers = _lightCastBuffers;


- (instancetype)initWithCommandQueue:(id<MTLCommandQueue>)commandQueue
                     withAccelerator:(NuoRayAccelerateStructure*)accelerateSturcture
                       withSceneRoot:(NuoMeshSceneRoot*)sceneRoot
                 withSceneParameters:(ModelSceneParameters*)sceneParam
{
    if (self = [super initWithCommandQueue:commandQueue])
    {
        _shadowMapRenderer[0] = [[NuoShadowMapRenderer alloc] initWithCommandQueue:commandQueue withName:@"Shadow 0"];
        _shadowMapRenderer[1] = [[NuoShadowMapRenderer alloc] initWithCommandQueue:commandQueue withName:@"Shadow 1"];
        
        _immediateTarget = [[NuoRenderPassTarget alloc] initWithCommandQueue:commandQueue
                                                             withPixelFormat:MTLPixelFormatBGRA8Unorm
                                                             withSampleCount:kSampleCount];
        _immediateTarget.name = @"immediate";
        _immediateTarget.manageTargetTexture = YES;
        _immediateTarget.sharedTargetTexture = NO;
        
        _illuminationRenderer = [[ModelRayTracingBlendRenderer alloc] initWithCommandQueue:commandQueue
                                                                           withPixelFormat:MTLPixelFormatBGRA8Unorm
                                                                           withSampleCount:1];
        
        _rayTracingRenderer = [[ModelRayTracingRenderer alloc] initWithCommandQueue:commandQueue];
        _rayTracingRenderer.rayStructure = accelerateSturcture;
        
        _lightCastBuffers = [[NuoBufferSwapChain alloc] initWithDevice:self.commandQueue.device
                                                        WithBufferSize:sizeof(NuoLightVertexUniforms)
                                                           withOptions:MTLResourceStorageModeManaged
                                                         withChainSize:kInFlightBufferCount];
        
        _sceneRoot = sceneRoot;
        
        sceneParam.shadowMap = self;
        self.paramsProvider = sceneParam;
    }
    
    return self;
}


- (void)setRayTracingRecordStatus:(RecordStatus)rayTracingRecordStatus
{
    BOOL changed = (_rayTracingRecordStatus != rayTracingRecordStatus);
    
    _rayTracingRecordStatus = rayTracingRecordStatus;
    
    if (rayTracingRecordStatus == kRecord_Stop)
        [_rayTracingRenderer resetResources];
    
    if (changed)
    {
        [_sceneRoot setShadowOptionRayTracing:_rayTracingRecordStatus != kRecord_Stop];
        [_sceneRoot makeGPUStates];
    }
}


- (void)setDrawableSize:(CGSize)drawableSize
{
    [_immediateTarget setDrawableSize:drawableSize];
    [_shadowMapRenderer[0] setDrawableSize:drawableSize];
    [_shadowMapRenderer[1] setDrawableSize:drawableSize];
    
    [_rayTracingRenderer setDrawableSize:drawableSize];
    [_illuminationRenderer setDrawableSize:drawableSize];
}


- (void)setSampleCount:(NSUInteger)count
{
    // no calling to shadow map render. they are not MSAA-ed
    
    [_immediateTarget setSampleCount:count];
}


- (void)setAmbientParameters:(const NuoAmbientUniformField&)ambientParameters
{
    _ambientParameters = ambientParameters;
}


- (void)setAmbient:(const NuoVectorFloat3&)ambient
{
    _ambient = ambient;
    [_illuminationRenderer setAmbient:ambient];
}


- (void)setResolveDepth:(BOOL)resolveDepth
{
    [_immediateTarget setResolveDepth:resolveDepth];
}


- (id<MTLTexture>)depthMap
{
    return _immediateTarget.depthTexture;
}


- (id<MTLTexture>)shadowMap:(uint)index withMask:(NuoSceneMask)mask
{
    if (_rayTracingRecordStatus != kRecord_Stop)
        return [_rayTracingRenderer shadowForLightSource:index withMask:mask];
    else
        return _shadowMapRenderer[index].renderTarget.targetTexture;
}


- (void)rayStructUpdated
{
    [_rayTracingRenderer rayStructUpdated];
}


- (void)predrawWithCommandBuffer:(NuoCommandBuffer*)commandBuffer
            withRayStructChanged:(BOOL)changed
           withRayStructAdjusted:(BOOL)adjusted
{
    assert(_rayTracingRecordStatus != kRecord_Stop);
    
    if (changed)
        [_rayTracingRenderer rayStructUpdated];
        
    if (adjusted)
    {
        const NuoBounds bounds = [_sceneRoot worldBounds:self.viewMatrix].boundingBox;
        
        NuoRayTracingGlobalIlluminationParam illumParams;
        illumParams.ambient = _ambient._vector;
        illumParams.ambientRadius = _ambientParameters.sampleRadius;
        illumParams.illuminationStrength = self.illuminationStrength;
        illumParams.specularMaterialAdjust = self.lights[0].lightingSpecular;
        
        _rayTracingRenderer.sceneBounds = bounds;
        _rayTracingRenderer.globalIllum = illumParams;
        _rayTracingRenderer.fieldOfView = self.fieldOfView;
    }
    
    for (uint i = 0; i < 2; ++i)
        [_rayTracingRenderer setLightSource:self.lights[i] forIndex:i];
    
    if (_rayTracingRecordStatus == kRecord_Start)
    {
        [_rayTracingRenderer drawWithCommandBuffer:commandBuffer];
    }
}


- (void)drawWithCommandBufferPriorBackdrop:(NuoCommandBuffer *)commandBuffer
{
    if (_rayTracingRecordStatus != kRecord_Stop)
    {
        return;
    }
    
    // get the target render pass and draw the scene in the forward rendering
    //
    NuoRenderPassEncoder* renderPass = [_immediateTarget retainRenderPassEndcoder:commandBuffer];
    
    if (!renderPass)
        return;
    
    renderPass.label = @"Scene Render Pass";
    
    [self setSceneBuffersTo:renderPass];
    [_sceneRoot drawMesh:renderPass];
    
    [_immediateTarget releaseRenderPassEndcoder];
    
    NuoInspectableMaster* inspectMaster = [NuoInspectableMaster sharedMaster];
    [inspectMaster updateTexture:_immediateTarget.targetTexture forName:kInspectable_Immediate];
    [inspectMaster updateTexture:_immediateTarget.targetTexture forName:kInspectable_ImmediateAlpha];
}



- (void)drawWithCommandBuffer:(NuoCommandBuffer *)commandBuffer
{
    NuoInspectableMaster* inspectMaster = [NuoInspectableMaster sharedMaster];
    
    assert(_rayTracingRecordStatus != kRecord_Stop);
    
    NSArray* textures = _rayTracingRenderer.targetTextures;
        
    [inspectMaster updateTexture:textures[0] forName:kInspectable_Illuminate];
    
    [_illuminationRenderer setRenderTarget:_delegateTarget];
    [_illuminationRenderer setImmediateResult:_rayTracingRenderer.targetTextures[2]];
    [_illuminationRenderer setIllumination:textures[0]];
    [_illuminationRenderer setIlluminationOnVirtual:textures[1]];
    
    [_illuminationRenderer drawWithCommandBuffer:commandBuffer];
}


- (void)setDelegateTarget:(NuoRenderPassTarget*)target
{
    _delegateTarget = target;
}



@end
