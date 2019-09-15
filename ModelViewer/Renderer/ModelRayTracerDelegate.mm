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
#import "ModelRayTracingRenderer.h"
#import "ModelRayTracingBlendRenderer.h"
#import "NuoInspectableMaster.h"

#include "NuoMeshSceneRoot.h"



@implementation ModelRayTracerDelegate
{
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
{
    if (self = [super init])
    {
        self.commandQueue = commandQueue;
        
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
    [_rayTracingRenderer setDrawableSize:drawableSize];
    [_illuminationRenderer setDrawableSize:drawableSize];
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
    
    [_rayTracingRenderer setLightSources:self.lights];
    
    if (_rayTracingRecordStatus == kRecord_Start)
    {
        [_rayTracingRenderer drawWithCommandBuffer:commandBuffer];
    }
}


- (void)drawWithCommandBufferPriorBackdrop:(NuoCommandBuffer *)commandBuffer
{
}



- (void)drawWithCommandBuffer:(NuoCommandBuffer *)commandBuffer
{
    NuoInspectableMaster* inspectMaster = [NuoInspectableMaster sharedMaster];
    
    assert(_rayTracingRecordStatus != kRecord_Stop);
    
    NSArray* textures = _rayTracingRenderer.targetTextures;
        
    [inspectMaster updateTexture:textures[kModelRayTracingTargets_AmbientNormal] forName:kInspectable_Illuminate];
    
    [_illuminationRenderer setRenderTarget:_delegateTarget];
    [_illuminationRenderer setImmediateResult:textures[kModelRayTracingTargets_Direct]];
    [_illuminationRenderer setIllumination:textures[kModelRayTracingTargets_AmbientNormal]];
    [_illuminationRenderer setIlluminationOnVirtual:textures[kModelRayTracingTargets_AmbientVirtual]];
    // virtual NB
    [_illuminationRenderer setDirectLightVirtual:textures[kModelRayTracingTargets_DirectVirtual]];
    [_illuminationRenderer setDirectLightVirtualBlocked:textures[kModelRayTracingTargets_DirectVirtualBlocked]];
    
    [_illuminationRenderer drawWithCommandBuffer:commandBuffer];
}


- (void)setDelegateTarget:(NuoRenderPassTarget*)target
{
    _delegateTarget = target;
}



@end
