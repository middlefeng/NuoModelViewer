//
//  ModelRayTracingRenderer.m
//  ModelViewer
//
//  Created by middleware on 6/22/18.
//  Copyright © 2020 middleware. All rights reserved.
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
#import "NuoTextureAverageMesh.h"
#import "NuoArgumentBuffer.h"

#include "NuoTypes.h"
#include "NuoRayTracingRandom.h"
#include "NuoComputeEncoder.h"
#include "NuoRenderPassAttachment.h"



static const uint32_t kRandomBufferSize = 256;
static const uint32_t kRayBounce = 4;


enum kModelRayTracingTargets
{
    kModelRayTracingTargets_RegularLighting = 0,
    kModelRayTracingTargets_AmbientVirtual,
    kModelRayTracingTargets_AmbientVirtualNB,
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
    NuoRayBuffer* _lightRayByScatterBuffer;
    
    NuoIlluminationTarget* _rayTracingResult;
    NuoRayVisibility* _primaryRayVisibility;
    NuoRayVisibility* _shadowRayVisibility;
    NuoRayVisibility* _lightRayByScatterVisibility;
    
    PNuoRayTracingRandom _rng;
    CGSize _drawableSize;
    
    // inspectable resources
    NuoComputePipeline* _intersectionPipeline;
    NSMutableDictionary<NSString*, NuoArgumentBuffer*>* _inspectTargets;
    NSMutableDictionary<NSString*, NuoTargetAccumulator*>* _inspectAccumulators;
}


- (instancetype)initWithCommandQueue:(id<MTLCommandQueue>)commandQueue
{
    self = [super initWithCommandQueue:commandQueue
                       withPixelFormat:MTLPixelFormatRGBA32Float
                       withTargetCount:6 /* 2 for ambient/local-illumination on virtual surfaces,
                                          * 1 for regular lighting (including indirect on virtual),
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
        
        _shadowRayVisibility = [[NuoRayVisibility alloc] initWithCommandQueue:commandQueue];
        _shadowRayVisibility.rayStride = kRayBufferStride;
        _shadowRayVisibility.rayTracer = self;
        
        _lightRayByScatterVisibility = [[NuoRayVisibility alloc] initWithCommandQueue:commandQueue];
        _lightRayByScatterVisibility.rayStride = kRayBufferStride;
        _lightRayByScatterVisibility.rayTracer = self;
        
        _inspectTargets = [NSMutableDictionary new];
        _inspectAccumulators = [NSMutableDictionary new];
    }
    
    return self;
}


- (void)setMultipleImportanceSampling:(bool)multipleImportanceSampling
{
    _multipleImportanceSampling = multipleImportanceSampling;
    
    [_primaryAndIncidentRaysPipeline setFunctionConstantBool:_multipleImportanceSampling at:0];
    [_pimraryVirtualLighting setFunctionConstantBool:_multipleImportanceSampling at:0];
    [_rayShadePipeline setFunctionConstantBool:_multipleImportanceSampling at:0];
}


- (void)setIndirectSpecular:(bool)indirectSpecular
{
    _indirectSpecular = indirectSpecular;
       
    [_primaryAndIncidentRaysPipeline setFunctionConstantBool:_indirectSpecular at:1];
    [_pimraryVirtualLighting setFunctionConstantBool:_indirectSpecular at:1];
    [_rayShadePipeline setFunctionConstantBool:_indirectSpecular at:1];
}


- (void)resetResources
{
    [super resetResources];
    [_inspectAccumulators enumerateKeysAndObjectsUsingBlock:^(NSString* key,
                                                              NuoTargetAccumulator * a,
                                                              BOOL* stop)
        { [a reset]; }];
}



- (void)setDrawableSize:(CGSize)drawableSize
{
    [super setDrawableSize:drawableSize];
    
    if (CGSizeEqualToSize(_drawableSize, drawableSize))
        return;
    
    _drawableSize = drawableSize;
    
    _incidentRaysBuffer = [[NuoRayBuffer alloc] initWithCommandQueue:self.commandQueue];
    _incidentRaysBuffer.dimension = drawableSize;
    
    _shadowRaysBuffer = [[NuoRayBuffer alloc] initWithCommandQueue:self.commandQueue];
    _shadowRaysBuffer.dimension = drawableSize;
    
    _lightRayByScatterBuffer = [[NuoRayBuffer alloc] initWithCommandQueue:self.commandQueue];
    _lightRayByScatterBuffer.dimension = drawableSize;
    
    [_primaryRayVisibility setDrawableSize:drawableSize];
    [_shadowRayVisibility setDrawableSize:drawableSize];
    [_lightRayByScatterVisibility setDrawableSize:drawableSize];
    
    [_inspectAccumulators enumerateKeysAndObjectsUsingBlock:^(NSString* key,
                                                              NuoTargetAccumulator * a,
                                                              BOOL* stop)
        { [a setDrawableSize:_drawableSize]; }];
    [_inspectTargets removeAllObjects];
}


- (void)updateUniforms:(id<NuoRenderInFlight>)inFlight
{
    NuoRayTracingUniforms uniforms;
    
    for (uint i = 0; i < 2; ++i)
    {
        NuoLightSource* lightSource = _lightSources[i];
        
        NuoRayTracingLightSource* lightSourceRayTracing = &(uniforms.lightSources[i]);
        NuoVectorFloat4 lightVec = NuoVectorFloat4(0.0, 0.0, 1.0, 0.0);
        
        lightSourceRayTracing->direction = (lightSource.lightDirection * lightVec)._vector.xyz;
        lightSourceRayTracing->irradiance = lightSource.lightingIrradiance;
        
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
        // inspect intersection
        [self inspectIntersection:commandBuffer forName:kInspectable_RayTracingIntersecVir
              withRayTraceUniform:rayTraceUniform];
        
        // generate rays for the two light sources, from virtual objects
        //
        [self runRayTraceCompute:_pimraryVirtualLighting withCommandBuffer:commandBuffer
                   withParameter:@[rayTraceUniform, randomBuffer,
                                   _shadowRaysBuffer.buffer]];
    }
    
    [self updatePrimaryRayMask:kNuoRayIndex_OnTranslucent withCommandBuffer:commandBuffer];
    
    if ([self primaryRayIntersect:commandBuffer])
    {
        // inspect intersection
        [self inspectIntersection:commandBuffer forName:kInspectable_RayTracingIntersec
              withRayTraceUniform:rayTraceUniform];
        
        _primaryRayVisibility.tracingUniform = rayTraceUniform;
        
        // generate rays for the two light sources, from translucent objects
        //
        [self runRayTraceCompute:_primaryAndIncidentRaysPipeline withCommandBuffer:commandBuffer
                   withParameter:@[rayTraceUniform, randomBuffer,
                                   _shadowRaysBuffer.buffer,
                                   _lightRayByScatterBuffer.buffer,
                                   _incidentRaysBuffer.buffer]];
        
        [_primaryRayVisibility visibilityTestInit:commandBuffer];
        
        for (uint i = 0; i < kRayBounce; ++i)
        {
            _shadowRayVisibility.paths = _shadowRaysBuffer;
            _shadowRayVisibility.tracingUniform = rayTraceUniform;
            [_shadowRayVisibility visibilityTestInit:commandBuffer];
            
            [self rayIntersect:commandBuffer withRays:_incidentRaysBuffer withIntersection:self.intersectionBuffer];
            
            if (_multipleImportanceSampling)
            {
                _lightRayByScatterVisibility.paths = _lightRayByScatterBuffer;
                _lightRayByScatterVisibility.tracingUniform = rayTraceUniform;
                [_lightRayByScatterVisibility visibilityTestInit:commandBuffer];
            }
            
            for (uint i = 0; i < kRayBounce; ++i)
            {
                [_shadowRayVisibility visibilityTest:commandBuffer];
                
                if (_multipleImportanceSampling)
                    [_lightRayByScatterVisibility visibilityTest:commandBuffer];
            }
            
            [_primaryRayVisibility visibilityTest:commandBuffer];
            
            [self runRayTraceCompute:_rayShadePipeline withCommandBuffer:commandBuffer
                       withParameter:@[rayTraceUniform, randomBuffer,
                                       _shadowRaysBuffer.buffer,
                                       _lightRayByScatterBuffer.buffer,
                                       _primaryRayVisibility.visibilities,
                                       _shadowRayVisibility.visibilities,
                                       _lightRayByScatterVisibility.visibilities]
                      withExitantRay:_incidentRaysBuffer.buffer
                    withIntersection:self.intersectionBuffer];
        }
    }
    
    NuoIlluminationTarget* targets = self.rayTracingResult;
        
    NuoInspectableMaster* inspect = [NuoInspectableMaster sharedMaster];
    [inspect updateTexture:targets.regularLighting forName:kInspectable_RayTracing];
    [inspect updateTexture:targets.directVirtualBlocked forName:kInspectable_RayTracingVirtualBlocked];
    [inspect updateTexture:targets.ambientVirtualWithoutBlock forName:kInspectable_AmbientVirtualWithoutBlock];
}


- (void)inspectIntersection:(NuoCommandBuffer*)commandBuffer
                    forName:(NSString*)name withRayTraceUniform:(id<MTLBuffer>)rayTraceUniform
{
    NuoInspectableMaster* inspect = [NuoInspectableMaster sharedMaster];
    if (![inspect isInspected:name])
    {
        return;
    }
    
    id<MTLDevice> device = commandBuffer.commandQueue.device;
    
    if (!_intersectionPipeline)
    {
        _intersectionPipeline = [[NuoComputePipeline alloc] initWithDevice:device
                                                              withFunction:@"intersection_visualize"];
    }
    
    NuoTargetAccumulator* accumlator = [_inspectAccumulators objectForKey:name];
    if (accumlator == nil)
    {
        accumlator = [[NuoTargetAccumulator alloc] initWithCommandQueue:commandBuffer.commandQueue
                                                        withPixelFormat:MTLPixelFormatRGBA32Float
                                                               withName:@"Ray Tracing Intersection Visualization"];
        [accumlator setDrawableSize:_drawableSize];
        [_inspectAccumulators setObject:accumlator forKey:name];
    }
    
    [accumlator clearRenderTargetWithCommandBuffer:commandBuffer];
    
    NuoComputeEncoder* encoder = [_intersectionPipeline encoderWithCommandBuffer:commandBuffer];
    
    NuoArgumentBuffer* target = [_inspectTargets objectForKey:name];
    if (!target)
    {
        // this must happen after [_intersectionPipeline encoderWithCommandBuffer ...], or the
        // creation of an argument encoder fails
        //
        id<MTLArgumentEncoder> encoder = [_intersectionPipeline argumentEncoder:1];
        
        target = [NuoArgumentBuffer new];
        [target encodeWith:encoder forIndex:1];
        [target setTexture:accumlator.renderTarget.targetTexture
                       for:(MTLTextureUsageShaderRead | MTLTextureUsageShaderWrite) atIndex:0];
        
        [_inspectTargets setObject:target forKey:name];
    }
    
    [self runRayTraceCompute:_intersectionPipeline
                 withEncoder:encoder withTargets:target
               withParameter:@[rayTraceUniform] withExitantRay:nil
            withIntersection:self.intersectionBuffer];
    
    [accumlator accumulateWithCommandBuffer:commandBuffer];
    [inspect updateTexture:accumlator.accumulateTarget.targetTexture forName:name];
}



- (NuoIlluminationTarget*)rayTracingResult
{
    NSArray<id<MTLTexture>>* textures = self.targetTextures;
    
    // ambient has been part of regularLighting in ray tracing
    //
    assert(_rayTracingResult.ambientNormal == nil);
    
    _rayTracingResult.regularLighting = textures[kModelRayTracingTargets_RegularLighting];
    _rayTracingResult.ambientVirtual = textures[kModelRayTracingTargets_AmbientVirtual];
    _rayTracingResult.ambientVirtualWithoutBlock = textures[kModelRayTracingTargets_AmbientVirtualNB];
    _rayTracingResult.directVirtual = textures[kModelRayTracingTargets_DirectVirtual];
    _rayTracingResult.directVirtualBlocked = textures[kModelRayTracingTargets_DirectVirtualBlocked];
    _rayTracingResult.modelMask = textures[kModelRayTracingTargets_ModelMask];
    
    return _rayTracingResult;
}



@end
