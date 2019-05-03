//
//  ModelRayTracingRenderer.m
//  ModelViewer
//
//  Created by middleware on 6/22/18.
//  Copyright © 2018 middleware. All rights reserved.
//

#import "ModelRayTracingRenderer.h"
#import "NuoRayTracingUniform.h"

#import "NuoLightSource.h"

#import "NuoRayBuffer.h"
#import "NuoRayAccelerateStructure.h"

#include "NuoRandomBuffer.h"
#include "NuoComputeEncoder.h"
#include "NuoRenderPassAttachment.h"



static const uint32_t kRandomBufferSize = 256;
static const uint32_t kRayBounce = 4;


@interface ModelRayTracingSubrenderer : NuoRayTracingRenderer

@property (nonatomic, readonly) NuoRayBuffer* shadowRayBuffer;
@property (nonatomic, readonly) NuoRayBuffer* shadowRayBufferOnTranslucent;

@property (nonatomic, readonly) id<MTLBuffer> shadowIntersectionBuffer;
@property (nonatomic, weak) NuoLightSource* lightSource;

@property (nonatomic, readonly) NSArray<NuoRenderPassTarget*>* normalizedIllumination;

- (instancetype)initWithCommandQueue:(id<MTLCommandQueue>)commandQueue;

@end




@implementation ModelRayTracingSubrenderer
{
    NuoComputePipeline* _shadowShadePipeline;
    NuoComputePipeline* _shadowShadePipelineOnTranslucent;
    
    NuoComputePipeline* _differentialPipeline;
    CGSize _drawableSize;
}


- (instancetype)initWithCommandQueue:(id<MTLCommandQueue>)commandQueue
{
    // use two channels for the opaque and translucent objects, respectivey
    //
    MTLPixelFormat format = MTLPixelFormatRGBA32Float;
    
    self = [super initWithCommandQueue:commandQueue
                       withPixelFormat:format
                       withTargetCount:4 /* 2 for opaque, 2 for translucent */];
    
    if (self)
    {
        _shadowShadePipeline = [[NuoComputePipeline alloc] initWithDevice:commandQueue.device
                                                             withFunction:@"shadow_contribute"
                                                            withParameter:NO];
        _shadowShadePipelineOnTranslucent = [[NuoComputePipeline alloc] initWithDevice:commandQueue.device
                                                                          withFunction:@"shadow_contribute"
                                                                         withParameter:YES];
        _differentialPipeline = [[NuoComputePipeline alloc] initWithDevice:commandQueue.device
                                                              withFunction:@"shadow_illuminate"
                                                             withParameter:YES];
        
        _shadowShadePipeline.name = @"Shadow Shade (Opaque)";
        _shadowShadePipelineOnTranslucent.name = @"Shadow Shade (Translucent)";
        _differentialPipeline.name = @"Illumination Normalizing";
        
        NuoRenderPassTarget* illumination[2];
        for (uint i = 0; i < 2; ++i)
        {
            illumination[i] = [[NuoRenderPassTarget alloc] initWithCommandQueue:commandQueue
                                                                withPixelFormat:format
                                                                withSampleCount:1];
            
            NuoRenderPassTarget* illum = illumination[i];
            
            illum.manageTargetTexture = YES;
            illum.sharedTargetTexture = NO;
            illum.clearColor = MTLClearColorMake(0.0, 0.0, 0.0, 1.0);
            illum.colorAttachments[0].needWrite = YES;
            illum.name = @"Ray Tracing Normalized";
        }
        
        _normalizedIllumination = [[NSArray alloc] initWithObjects:illumination count:2];
    }
    
    return self;
}


- (void)setDrawableSize:(CGSize)drawableSize
{
    [super setDrawableSize:drawableSize];
    
    if (CGSizeEqualToSize(_drawableSize, drawableSize))
        return;
    
    _drawableSize = drawableSize;
    for (NuoRenderPassTarget* illum in _normalizedIllumination)
        illum.drawableSize = drawableSize;
    
    const size_t intersectionSize = drawableSize.width * drawableSize.height * kRayIntersectionStride;
    
    _shadowRayBuffer = [[NuoRayBuffer alloc] initWithDevice:self.commandQueue.device];
    _shadowRayBuffer.dimension = _drawableSize;
    
    _shadowRayBufferOnTranslucent = [[NuoRayBuffer alloc] initWithDevice:self.commandQueue.device];
    _shadowRayBufferOnTranslucent.dimension = _drawableSize;
    
    _shadowIntersectionBuffer = [self.commandQueue.device newBufferWithLength:intersectionSize
                                                                      options:MTLResourceStorageModePrivate];
}


- (void)runRayTraceShade:(id<MTLCommandBuffer>)commandBuffer withInFlightIndex:(unsigned int)inFlight
{
    [self rayIntersect:commandBuffer withRays:_shadowRayBuffer withIntersection:_shadowIntersectionBuffer];
    
    [self runRayTraceCompute:_shadowShadePipeline withCommandBuffer:commandBuffer
                withParameter:@[_shadowRayBuffer.buffer]
            withIntersection:_shadowIntersectionBuffer withInFlightIndex:inFlight];
    
    [self rayIntersect:commandBuffer withRays:_shadowRayBufferOnTranslucent withIntersection:_shadowIntersectionBuffer];
    
    [self runRayTraceCompute:_shadowShadePipelineOnTranslucent withCommandBuffer:commandBuffer
               withParameter:@[_shadowRayBufferOnTranslucent.buffer]
            withIntersection:_shadowIntersectionBuffer withInFlightIndex:inFlight];
}



- (void)drawWithCommandBuffer:(id<MTLCommandBuffer>)commandBuffer withInFlightIndex:(unsigned int)inFlight
{
    [super drawWithCommandBuffer:commandBuffer withInFlightIndex:inFlight];
    
    for (NuoRenderPassTarget* illum in _normalizedIllumination)
    {
        [illum retainRenderPassEndcoder:commandBuffer withInFlight:0];
        [illum releaseRenderPassEndcoder];
    }
    
    NuoComputeEncoder* encoder = [_differentialPipeline encoderWithCommandBuffer:commandBuffer];
    
    NSArray<id<MTLTexture>>* textures = self.targetTextures;
    
    uint i = 0;
    for (; i < textures.count; ++i)
        [encoder setTexture:textures[i] atIndex:i];

    [encoder setTexture:_normalizedIllumination[0].targetTexture atIndex:i];
    [encoder setTexture:_normalizedIllumination[1].targetTexture atIndex:i+1];
    
    [encoder dispatch];
}



@end




@implementation ModelRayTracingRenderer
{
    NuoComputePipeline* _primaryRaysPipeline;
    NuoComputePipeline* _rayShadePipeline;
    
    NSArray<id<MTLBuffer>>* _rayTraceUniform;
    NSArray<id<MTLBuffer>>* _randomBuffers;
    
    ModelRayTracingSubrenderer* _subRenderers[2];
    
    NuoRayBuffer* _incidentRaysBuffer;
    
    PRandomGenerator _rng;
}


- (instancetype)initWithCommandQueue:(id<MTLCommandQueue>)commandQueue
{
    self = [super initWithCommandQueue:commandQueue
                       withPixelFormat:MTLPixelFormatRGBA32Float withTargetCount:1];
    
    if (self)
    {
        _primaryRaysPipeline = [[NuoComputePipeline alloc] initWithDevice:commandQueue.device
                                                               withFunction:@"primary_ray_process"
                                                              withParameter:NO];
        _primaryRaysPipeline.name = @"Primary Ray Process";
        
        _rayShadePipeline = [[NuoComputePipeline alloc] initWithDevice:commandQueue.device
                                                          withFunction:@"incident_ray_process" withParameter:NO];
        _rayShadePipeline.name = @"Incident Ray Shading";
        
        id<MTLBuffer> buffers[kInFlightBufferCount];
        id<MTLBuffer> randoms[kInFlightBufferCount];
        _rng = std::make_shared<RandomGenerator>(kRandomBufferSize, kRayBounce, 1);
        for (uint i = 0; i < kInFlightBufferCount; ++i)
        {
            buffers[i] = [commandQueue.device newBufferWithLength:sizeof(NuoRayTracingUniforms)
                                                          options:MTLResourceStorageModeManaged];
            randoms[i] = [commandQueue.device newBufferWithLength:_rng->BytesSize()
                                                          options:MTLResourceStorageModeManaged];
        }
        _rayTraceUniform = [[NSArray alloc] initWithObjects:buffers count:kInFlightBufferCount];
        _randomBuffers = [[NSArray alloc] initWithObjects:randoms count:kInFlightBufferCount];
        
        for (uint i = 0; i < 2; ++i)
            _subRenderers[i] = [[ModelRayTracingSubrenderer alloc] initWithCommandQueue:commandQueue];
    }
    
    return self;
}


- (void)setDrawableSize:(CGSize)drawableSize
{
    [super setDrawableSize:drawableSize];
    
    for (ModelRayTracingSubrenderer* renderer : _subRenderers)
        [renderer setDrawableSize:drawableSize];
    
    _incidentRaysBuffer = [[NuoRayBuffer alloc] initWithDevice:self.commandQueue.device];
    _incidentRaysBuffer.dimension = drawableSize;
}


- (void)setLightSource:(NuoLightSource*)lightSource forIndex:(uint)index
{
    [_subRenderers[index] setLightSource:lightSource];
}


- (void)resetResources:(id<MTLCommandBuffer>)commandBuffer
{
    id<MTLCommandBuffer> localCommandBuffer = commandBuffer ? commandBuffer : [self.commandQueue commandBuffer];
    
    for (ModelRayTracingSubrenderer* renderer : _subRenderers)
        [renderer resetResources:localCommandBuffer];
    
    [super resetResources:commandBuffer];
    
    if (!commandBuffer)
        [localCommandBuffer commit];
}


- (void)updateUniforms:(uint32_t)index
{
    NuoRayTracingUniforms uniforms;
    
    for (uint i = 0; i < 2; ++i)
    {
        NuoLightSource* lightSource = _subRenderers[i].lightSource;
        const NuoMatrixFloat44 matrix = NuoMatrixRotation(lightSource.lightingRotationX, lightSource.lightingRotationY);
        uniforms.lightSources[i].direction = matrix._m;
        uniforms.lightSources[i].radius = lightSource.shadowSoften;
    }
    
    uniforms.bounds.span = _sceneBounds.MaxDimension();
    uniforms.bounds.center = NuoVectorFloat4(_sceneBounds._center._vector.x,
                                             _sceneBounds._center._vector.y,
                                             _sceneBounds._center._vector.z, 1.0)._vector;
    uniforms.globalIllum = _globalIllum;
    
    memcpy(_rayTraceUniform[index].contents, &uniforms, sizeof(NuoRayTracingUniforms));
    [_rayTraceUniform[index] didModifyRange:NSMakeRange(0, sizeof(NuoRayTracingUniforms))];
    
    _rng->SetBuffer(_randomBuffers[index].contents);
    _rng->UpdateBuffer();
    [_randomBuffers[index] didModifyRange:NSMakeRange(0, _rng->BytesSize())];
}


- (void)runRayTraceShade:(id<MTLCommandBuffer>)commandBuffer withInFlightIndex:(unsigned int)inFlight
{
    // the shadow maps in the screen space are integrated by the sub renderers.
    // the master ray tracing renderer integrates the overlay result, e.g. self-illumination
    
    [self updateUniforms:inFlight];
    
    [self primaryRayEmit:commandBuffer withInFlightIndex:inFlight];
    
    if ([self primaryRayIntersect:commandBuffer withInFlightIndex:inFlight])
    {
        // generate rays for the two light sources, from opaque objects
        //
        [self runRayTraceCompute:_primaryRaysPipeline withCommandBuffer:commandBuffer
                   withParameter:@[_rayTraceUniform[inFlight],
                                   _randomBuffers[inFlight],
                                   _subRenderers[0].shadowRayBuffer.buffer,
                                   _subRenderers[1].shadowRayBuffer.buffer,
                                   _incidentRaysBuffer.buffer]
                withIntersection:self.intersectionBuffer
               withInFlightIndex:inFlight];
    }
    
    [self updatePrimaryRayMask:kNuoRayMask_Translucent withCommandBuffer:commandBuffer withInFlight:inFlight];
    
    if ([self primaryRayIntersect:commandBuffer withInFlightIndex:inFlight])
    {
        // generate rays for the two light sources, from translucent objects
        //
        [self runRayTraceCompute:_primaryRaysPipeline withCommandBuffer:commandBuffer
                   withParameter:@[_rayTraceUniform[inFlight],
                                   _randomBuffers[inFlight],
                                   _subRenderers[0].shadowRayBufferOnTranslucent.buffer,
                                   _subRenderers[1].shadowRayBufferOnTranslucent.buffer,
                                   _incidentRaysBuffer.buffer]
                withIntersection:self.intersectionBuffer
               withInFlightIndex:inFlight];
        
        for (uint i = 0; i < kRayBounce; ++i)
        {
            [self rayIntersect:commandBuffer withRays:_incidentRaysBuffer withIntersection:self.intersectionBuffer];
            
            [self runRayTraceCompute:_rayShadePipeline withCommandBuffer:commandBuffer
                       withParameter:@[_rayTraceUniform[inFlight], _randomBuffers[inFlight], _incidentRaysBuffer.buffer]
                    withIntersection:self.intersectionBuffer
                   withInFlightIndex:inFlight];
        }
    }
        
    for (uint i = 0; i < 2; ++i)
    {
        // sub renderers detect intersection for each light source
        // and accumulates the samplings
        //
        [_subRenderers[i] setRayStructure:self.rayStructure];
        [_subRenderers[i] drawWithCommandBuffer:commandBuffer withInFlightIndex:inFlight];
    }
}


- (id<MTLTexture>)shadowForLightSource:(uint)index withMask:(NuoSceneMask)mask
{
    uint i = (mask == kNuoSceneMask_Opaque ? 0 : 1);
    return _subRenderers[index].normalizedIllumination[i].targetTexture;
}




@end
