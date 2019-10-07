//
//  ModelRayTracingRenderer.m
//  ModelViewer
//
//  Created by middleware on 6/22/18.
//  Copyright © 2018 middleware. All rights reserved.
//

#import "ModelRayTracingRenderer.h"

#import "NuoInspectableMaster.h"
#import "NuoLightSource.h"

#import "NuoIlluminationMesh.h"
#import "NuoCommandBuffer.h"
#import "NuoBufferSwapChain.h"
#import "NuoRayBuffer.h"
#import "NuoRayAccelerateStructure.h"
#import "NuoRayVisibility.h"

#include "NuoRayTracingRandom.h"
#include "NuoComputeEncoder.h"
#include "NuoRenderPassAttachment.h"



static const uint32_t kRandomBufferSize = 256;
static const uint32_t kRayBounce = 4;


enum kModelRayTracingTargets
{
    kModelRayTracingTargets_AmbientNormal = 0,
    kModelRayTracingTargets_AmbientVirtual,
    kModelRayTracingTargets_AmbientVirtualNB,
    kModelRayTracingTargets_Direct,
    kModelRayTracingTargets_DirectVirtual,
    kModelRayTracingTargets_DirectVirtualBlocked,
    kModelRayTracingTargets_ModelMask,
};


@implementation ModelRayTracingRenderer
{
    NuoComputePipeline* _pimraryVirtualLighting;
    NuoComputePipeline* _primaryAndIncidentRaysPipeline;
    NuoComputePipeline* _rayShadePipeline;
    
    NuoBufferSwapChain* _rayTraceUniform;
    NuoBufferSwapChain* _randomBuffers;
    
    NuoRayBuffer* _incidentRaysBuffer;
    NuoRayBuffer* _shadowRaysBuffer;
    id<MTLBuffer> _shadowIntersectionBuffer;
    
    NuoIlluminationTarget* _rayTracingResult;
    NuoRayVisibility* _primaryRayVisibility;
    
    PNuoRayTracingRandom _rng;
    CGSize _drawableSize;
}


- (instancetype)initWithCommandQueue:(id<MTLCommandQueue>)commandQueue
{
    self = [super initWithCommandQueue:commandQueue
                       withPixelFormat:MTLPixelFormatRGBA32Float
                       withTargetCount:7 /* 1 for ambient/local-illumination of normal
                                          * 2 for ambient/local-illumination on virtual surfaces,
                                          * 1 for direct lighting,
                                          * 2 for direct lighting on virtual surface
                                          * 1 for opaque object mask */ ];
    
    if (self)
    {
        _primaryAndIncidentRaysPipeline = [[NuoComputePipeline alloc] initWithDevice:commandQueue.device
                                                                        withFunction:@"primary_ray_process"];
        _pimraryVirtualLighting = [[NuoComputePipeline alloc] initWithDevice:commandQueue.device
                                                                withFunction:@"primary_ray_virtual"];
        
        _rayShadePipeline = [[NuoComputePipeline alloc] initWithDevice:commandQueue.device
                                                          withFunction:@"incident_ray_process"];
        
        
        _primaryAndIncidentRaysPipeline.name = @"Primary/Incident Ray Process";
        _pimraryVirtualLighting.name = @"Virtual Lighting";
        _rayShadePipeline.name = @"Incident Ray Shading";
        
        _rng = std::make_shared<NuoRayTracingRandom>(kRandomBufferSize, kRayBounce, 1);
        _rayTraceUniform = [[NuoBufferSwapChain alloc] initWithDevice:commandQueue.device
                                                       WithBufferSize:sizeof(NuoRayTracingUniforms)
                                                          withOptions:MTLResourceStorageModeManaged
                                                        withChainSize:kInFlightBufferCount];
        _randomBuffers = [[NuoBufferSwapChain alloc] initWithDevice:commandQueue.device
                                                     WithBufferSize:_rng->BytesSize()
                                                        withOptions:MTLResourceStorageModeManaged
                                                      withChainSize:kInFlightBufferCount];
        
        _rayTracingResult = [NuoIlluminationTarget new];
        
        _primaryRayVisibility = [[NuoRayVisibility alloc] initWithCommandQueue:commandQueue];
        _primaryRayVisibility.rayStride = kRayBufferStride;
        _primaryRayVisibility.rayTracer = self;
    }
    
    return self;
}


- (void)setDrawableSize:(CGSize)drawableSize
{
    [super setDrawableSize:drawableSize];
    
    if (CGSizeEqualToSize(_drawableSize, drawableSize))
        return;
    
    _incidentRaysBuffer = [[NuoRayBuffer alloc] initWithCommandQueue:self.commandQueue];
    _incidentRaysBuffer.dimension = drawableSize;
    
    _shadowRaysBuffer = [[NuoRayBuffer alloc] initWithCommandQueue:self.commandQueue];
    _shadowRaysBuffer.dimension = drawableSize;
    
    const size_t intersectionSize = drawableSize.width * drawableSize.height * kRayIntersectionStride;
    _shadowIntersectionBuffer = [self.commandQueue.device newBufferWithLength:intersectionSize
                                                                      options:MTLResourceStorageModePrivate];
    
    [_primaryRayVisibility setDrawableSize:drawableSize];
}


- (void)updateUniforms:(id<NuoRenderInFlight>)inFlight
{
    NuoRayTracingUniforms uniforms;
    
    for (uint i = 0; i < 2; ++i)
    {
        NuoLightSource* lightSource = _lightSources[i];
        const NuoMatrixFloat44 matrix = NuoMatrixRotation(lightSource.lightingRotationX, lightSource.lightingRotationY);
        
        NuoRayTracingLightSource* lightSourceRayTracing = &(uniforms.lightSources[i]);
        
        lightSourceRayTracing->direction = matrix._m;
        lightSourceRayTracing->density = lightSource.lightingDensity;
        
        // the code used to pass lightSource.shadowSoften into the shader, which the shader had used as the diameter of
        // a disk which was distant from the lighted surface by the scene's dimension (i.e. maxDistance). in this
        // way, the calculation was duplicated for each pixel each ray, and would even duplicate in multiple places
        // among different shaders.
        //
        // now, the lightSource.shadowSoften is used as tangent of theta, with a scale factor that tries to
        // make the effect as close to the old behavior as possible. and the consine value is calculated from that
        // and passed to the shader. this approach need calculate the value once per render pass
        //
        float thetaTan = lightSource.shadowSoften / 2.0 * 0.25;
        lightSourceRayTracing->coneAngleCosine = (1 / sqrt(thetaTan * thetaTan + 1));
    }
    
    uniforms.bounds.span = _sceneBounds.MaxDimension();
    uniforms.bounds.center = NuoVectorFloat4(_sceneBounds._center._vector.x,
                                             _sceneBounds._center._vector.y,
                                             _sceneBounds._center._vector.z, 1.0)._vector;
    uniforms.globalIllum = _globalIllum;
    
    [_rayTraceUniform updateBufferWithInFlight:inFlight withContent:&uniforms];
    
    id<MTLBuffer> randomBuffer = [_randomBuffers bufferForInFlight:inFlight];
    _rng->SetBuffer(randomBuffer.contents);
    _rng->UpdateBuffer();
    [randomBuffer didModifyRange:NSMakeRange(0, _rng->BytesSize())];
}


- (void)runRayTraceShade:(NuoCommandBuffer*)commandBuffer
{
    // the shadow maps in the screen space are integrated by the sub renderers.
    // the master ray tracing renderer integrates the overlay result, e.g. self-illumination
    
    [self updateUniforms:commandBuffer];
    [self primaryRayEmit:commandBuffer];
    
    id<MTLBuffer> rayTraceUniform = [_rayTraceUniform bufferForInFlight:commandBuffer];
    id<MTLBuffer> randomBuffer = [_randomBuffers bufferForInFlight:commandBuffer];
    
    [self updatePrimaryRayMask:kNuoRayIndex_OnVirtual withCommandBuffer:commandBuffer];
    
    if ([self primaryRayIntersect:commandBuffer])
    {
        // generate rays for the two light sources, from virtual objects
        //
        [self runRayTraceCompute:_pimraryVirtualLighting withCommandBuffer:commandBuffer
                   withParameter:@[rayTraceUniform, randomBuffer,
                                   _shadowRaysBuffer.buffer]
                  withExitantRay:nil
                withIntersection:self.intersectionBuffer];
    }
    
    [self updatePrimaryRayMask:kNuoRayIndex_OnTranslucent withCommandBuffer:commandBuffer];
    
    if ([self primaryRayIntersect:commandBuffer])
    {
        _primaryRayVisibility.tracingUniform = rayTraceUniform;
        
        // generate rays for the two light sources, from translucent objects
        //
        [self runRayTraceCompute:_primaryAndIncidentRaysPipeline withCommandBuffer:commandBuffer
                   withParameter:@[rayTraceUniform, randomBuffer,
                                   _shadowRaysBuffer.buffer,
                                   _incidentRaysBuffer.buffer]
                  withExitantRay:nil
                withIntersection:self.intersectionBuffer];
        
        [_primaryRayVisibility visibilityTestInit:commandBuffer];
        
        for (uint i = 0; i < kRayBounce; ++i)
        {
            [self rayIntersect:commandBuffer withRays:_shadowRaysBuffer withIntersection:_shadowIntersectionBuffer];
            [self rayIntersect:commandBuffer withRays:_incidentRaysBuffer withIntersection:self.intersectionBuffer];
            [self rayIntersect:commandBuffer withRays:_primaryRayVisibility.spawnRays
                                     withIntersection:_primaryRayVisibility.spawnIntersection];
            
            [_primaryRayVisibility visibilityTest:commandBuffer];
            
            [self runRayTraceCompute:_rayShadePipeline withCommandBuffer:commandBuffer
                       withParameter:@[rayTraceUniform, randomBuffer,
                                       _shadowRaysBuffer.buffer,
                                       _shadowIntersectionBuffer,
                                       _primaryRayVisibility.visibilities]
                      withExitantRay:_incidentRaysBuffer.buffer
                    withIntersection:self.intersectionBuffer];
        }
    }
    
    NuoIlluminationTarget* targets = self.rayTracingResult;
        
    NuoInspectableMaster* inspect = [NuoInspectableMaster sharedMaster];
    [inspect updateTexture:targets.normal forName:kInspectable_RayTracing];
    [inspect updateTexture:targets.directVirtualBlocked forName:kInspectable_RayTracingVirtualBlocked];
    [inspect updateTexture:targets.ambientNormal forName:kInspectable_Illuminate];
    [inspect updateTexture:targets.ambientVirtualWithoutBlock forName:kInspectable_AmbientVirtualWithoutBlock];
}



- (NuoIlluminationTarget*)rayTracingResult
{
    NSArray<id<MTLTexture>>* textures = self.targetTextures;
    
    _rayTracingResult.normal = textures[kModelRayTracingTargets_Direct];
    _rayTracingResult.ambientNormal = textures[kModelRayTracingTargets_AmbientNormal];
    _rayTracingResult.ambientVirtual = textures[kModelRayTracingTargets_AmbientVirtual];
    _rayTracingResult.ambientVirtualWithoutBlock = textures[kModelRayTracingTargets_AmbientVirtualNB];
    _rayTracingResult.directVirtual = textures[kModelRayTracingTargets_DirectVirtual];
    _rayTracingResult.directVirtualBlocked = textures[kModelRayTracingTargets_DirectVirtualBlocked];
    _rayTracingResult.modelMask = textures[kModelRayTracingTargets_ModelMask];
    
    return _rayTracingResult;
}



@end
