//
//  ModelHybridRenderDelegate.m
//  ModelViewer
//
//  Created by Dong on 7/22/19.
//  Copyright © 2019 middleware. All rights reserved.
//

#import "ModelHybridRenderDelegate.h"

#import "NuoBufferSwapChain.h"
#import "NuoLightSource.h"
#import "NuoShadowMapRenderer.h"
#import "NuoDeferredRenderer.h"
#import "ModelHybridRenderer.h"
#import "ModelHybridBlendRenderer.h"
#import "NuoInspectableMaster.h"

#include "NuoTypes.h"
#include "NuoMeshSceneRoot.h"



@implementation ModelHybridRenderDelegate
{
    NuoShadowMapRenderer* _shadowMapRenderer[2];
    NuoRenderPassTarget* _immediateTarget;
    NuoDeferredRenderer* _deferredRenderer;
    ModelHybridBlendRenderer* _illuminationRenderer;
    
    ModelHybridRenderer* _rayTracingRenderer;
    
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
        
        _deferredRenderer = [[NuoDeferredRenderer alloc] initWithCommandQueue:commandQueue
                                                           withSceneParameter:sceneParam];
        
        _illuminationRenderer = [[ModelHybridBlendRenderer alloc] initWithCommandQueue:commandQueue
                                                                       withPixelFormat:MTLPixelFormatBGRA8Unorm
                                                                       withSampleCount:1];
        
        _rayTracingRenderer = [[ModelHybridRenderer alloc] initWithCommandQueue:commandQueue];
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
    [_deferredRenderer setDrawableSize:drawableSize];
    
    [_rayTracingRenderer setDrawableSize:drawableSize];
    [_illuminationRenderer setDrawableSize:drawableSize];
}


- (void)setSampleCount:(NSUInteger)count
{
    // no calling to shadow map render. they are not MSAA-ed

    [_immediateTarget setSampleCount:count];
    [_deferredRenderer setSampleCount:count];
}


- (void)setAmbientParameters:(const NuoAmbientUniformField&)ambientParameters
{
    _ambientParameters = ambientParameters;
    [_deferredRenderer setParameters:ambientParameters];
}


- (void)setAmbient:(const NuoVectorFloat3&)ambient
{
    _ambient = ambient;
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
    if (_rayTracingRecordStatus != kRecord_Stop)
    {
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
    }
    
    if (_rayTracingRecordStatus == kRecord_Start)
    {
        [_rayTracingRenderer drawWithCommandBuffer:commandBuffer];
        
        [_illuminationRenderer setDirectLighting:_rayTracingRenderer.directLight];
        [_illuminationRenderer predrawWithCommandBuffer:commandBuffer];
    }
    
    if (_rayTracingRecordStatus == kRecord_Stop)
    {
        // generate shadow map
        //
        for (unsigned int i = 0; i < 2 /* for two light sources only */; ++i)
        {
            _shadowMapRenderer[i].sceneRoot = _sceneRoot;
            _shadowMapRenderer[i].lightSource = self.lights[i];
            [_shadowMapRenderer[i] drawWithCommandBuffer:commandBuffer];
        }
        
        // store the light view point projection for shadow map detection in the scene
        //
        NuoLightVertexUniforms lightUniforms;
        lightUniforms.lightCastMatrix[0] = _shadowMapRenderer[0].lightCastMatrix._m;
        lightUniforms.lightCastMatrix[1] = _shadowMapRenderer[1].lightCastMatrix._m;
        
        [self.paramsProvider.lightCastBuffers updateBufferWithInFlight:commandBuffer withContent:&lightUniforms];
        
        // seems unnecessary with ray tracing running, and it slows down ray tracing on
        // 10.14.2 occasionally for unknown reason
        
        [_deferredRenderer setRoot:_sceneRoot];
        [_deferredRenderer predrawWithCommandBuffer:commandBuffer];
    }
}


- (void)drawWithCommandBufferPriorBackdrop:(NuoCommandBuffer *)commandBuffer
{
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
    
    if (_rayTracingRecordStatus != kRecord_Stop)
    {
        NuoIlluminationTarget* illuminations = _rayTracingRenderer.rayTracingResult;
        illuminations.regularLighting = _immediateTarget.targetTexture;
        
        [inspectMaster updateTexture:illuminations.ambientNormal forName:kInspectable_Illuminate];
        [inspectMaster updateTexture:illuminations.ambientVirtualWithoutBlock forName:kInspectable_AmbientVirtualWithoutBlock];
        
        [_illuminationRenderer setRenderTarget:_delegateTarget];
        [_illuminationRenderer setIlluminations:illuminations];
        [_illuminationRenderer setTranslucentMap:[_deferredRenderer ambientBuffer]];
        
        [_illuminationRenderer drawWithCommandBuffer:commandBuffer];
    }
    else
    {
        [_deferredRenderer setRenderTarget:_delegateTarget];
        [_deferredRenderer setImmediateResult:_immediateTarget.targetTexture];
        [_deferredRenderer drawWithCommandBuffer:commandBuffer];
    }
}


- (void)setDelegateTarget:(NuoRenderPassTarget*)target
{
    _delegateTarget = target;
}



@end
