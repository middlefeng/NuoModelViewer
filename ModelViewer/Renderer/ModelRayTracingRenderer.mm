//
//  ModelRayTracingRenderer.m
//  ModelViewer
//
//  Created by middleware on 6/22/18.
//  Copyright © 2018 middleware. All rights reserved.
//

#import "ModelRayTracingRenderer.h"
#import "NuoRayTracingUniform.h"

// headers to pass light source info
//
#import "NuoMeshSceneRenderPass.h"
#import "NuoShadowMapRenderer.h"
#import "NuoRayEmittor.h"

// TODO: remove
#import "NuoTextureMesh.h"

#include "NuoRandomBuffer.h"

#include <simd/simd.h>


static const uint32_t kRandomBufferSize = 512;




@interface ModelRayTracingSubrenderer()

@property (nonatomic, weak) id<MTLBuffer> shadowRayBuffer;
@property (nonatomic, weak) id<MTLBuffer> shadowIntersectionBuffer;

- (instancetype)initWithCommandQueue:(id<MTLCommandQueue>)commandQueue
                     withPixelFormat:(MTLPixelFormat)pixelFormat;

@end




@implementation ModelRayTracingSubrenderer
{
    id<MTLComputePipelineState> _shadowShadePipeline;
}


- (instancetype)initWithCommandQueue:(id<MTLCommandQueue>)commandQueue
{
    self = [super initWithCommandQueue:commandQueue withAccumulatedResult:YES];
    
    if (self)
    {
        NSError* error = nil;
        
        MTLFunctionConstantValues* values = [MTLFunctionConstantValues new];
        id<MTLLibrary> library = [commandQueue.device newDefaultLibrary];
        
        id<MTLFunction> shadowShadeFunction = [library newFunctionWithName:@"shadow_shade" constantValues:values error:&error];
        assert(error == nil);
        _shadowShadePipeline = [commandQueue.device newComputePipelineStateWithFunction:shadowShadeFunction error:&error];
        assert(error == nil);
    }
    
    return self;
}


- (void)runRayTraceShade:(id<MTLCommandBuffer>)commandBuffer withInFlightIndex:(unsigned int)inFlight
{
    [self runRayTraceCompute:_shadowShadePipeline withCommandBuffer:commandBuffer
                withParameter:@[_shadowRayBuffer]
            withIntersection:_shadowIntersectionBuffer withInFlightIndex:inFlight];
}



@end




@implementation ModelRayTracingRenderer
{
    id<MTLComputePipelineState> _shadowRayPipeline;
    
    NSArray<id<MTLBuffer>>* _rayTraceUniform;
    
    CGSize _shadowBufferSize;
    NSArray<id<MTLBuffer>>* _shadowRayBuffers;
    NSArray<id<MTLBuffer>>* _randomBuffers;
    NSArray<id<MTLBuffer>>* _shadowIntersectionBuffers;
    
    ModelRayTracingSubrenderer* _subRenderers[2];
}


- (instancetype)initWithCommandQueue:(id<MTLCommandQueue>)commandQueue
{
    self = [super initWithCommandQueue:commandQueue withAccumulatedResult:NO];
    
    if (self)
    {
        NSError* error = nil;
        MTLFunctionConstantValues* values = [MTLFunctionConstantValues new];
        id<MTLLibrary> library = [commandQueue.device newDefaultLibrary];
        
        id<MTLFunction> shadowRayFunction = [library newFunctionWithName:@"shadow_ray_emit" constantValues:values error:&error];
        assert(error == nil);
        _shadowRayPipeline = [commandQueue.device newComputePipelineStateWithFunction:shadowRayFunction error:&error];
        assert(error == nil);
        
        id<MTLBuffer> buffers[kInFlightBufferCount];
        id<MTLBuffer> randoms[kInFlightBufferCount];
        NuoRandomBuffer<NuoVectorFloat2::_typeTrait::_vectorType> randomBufferContent(kRandomBufferSize);
        for (uint i = 0; i < kInFlightBufferCount; ++i)
        {
            buffers[i] = [commandQueue.device newBufferWithLength:sizeof(NuoRayTracingUniforms)
                                                          options:MTLResourceStorageModeManaged];
            randoms[i] = [commandQueue.device newBufferWithLength:randomBufferContent.BytesSize()
                                                          options:MTLResourceStorageModeManaged];
        }
        _rayTraceUniform = [[NSArray alloc] initWithObjects:buffers count:kInFlightBufferCount];
        _randomBuffers = [[NSArray alloc] initWithObjects:randoms count:kInFlightBufferCount];
        
        for (uint i = 0; i < 2; ++i)
        {
            _subRenderers[i] = [[ModelRayTracingSubrenderer alloc] initWithCommandQueue:commandQueue];
        }
    }
    
    return self;
}


- (void)setDrawableSize:(CGSize)drawableSize
{
    [super setDrawableSize:drawableSize];
    
    if (CGSizeEqualToSize(_shadowBufferSize, drawableSize))
        return;
    
    const size_t bufferSize = drawableSize.width * drawableSize.height * kRayBufferStrid;
    const size_t intersectionSize = drawableSize.width * drawableSize.height * kRayBufferStrid;
    
    id<MTLBuffer> shadowRayBuffers[2];
    id<MTLBuffer> shadowIntersections[2];
    for (uint i = 0; i < 2; ++i)
    {
        shadowRayBuffers[i] = [self.commandQueue.device newBufferWithLength:bufferSize
                                                                    options:MTLResourceStorageModePrivate];
        shadowIntersections[i] = [self.commandQueue.device newBufferWithLength:intersectionSize
                                                                       options:MTLResourceStorageModePrivate];
        
        [_subRenderers[i] setDrawableSize:drawableSize];
    }
    
    _shadowRayBuffers = [[NSArray alloc] initWithObjects:shadowRayBuffers count:2];
    _shadowIntersectionBuffers = [[NSArray alloc] initWithObjects:shadowIntersections count:2];
    _shadowBufferSize = drawableSize;
}


- (void)setLightSource:(NuoLightSource*)lightSource forIndex:(uint)index
{
    [_subRenderers[index] setLightSource:lightSource];
}


- (void)resetResources
{
    for (uint i = 0; i < 2; ++i)
        [_subRenderers[i] resetResources];
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
    
    memcpy(_rayTraceUniform[index].contents, &uniforms, sizeof(NuoRayTracingUniforms));
    [_rayTraceUniform[index] didModifyRange:NSMakeRange(0, sizeof(NuoRayTracingUniforms))];
    
    NuoRandomBuffer<NuoVectorFloat2::_typeTrait::_vectorType> randomBuffer(kRandomBufferSize);
    memcpy([_randomBuffers[index] contents], randomBuffer.Ptr(), randomBuffer.BytesSize());
    
    [_randomBuffers[index] didModifyRange:NSMakeRange(0, randomBuffer.BytesSize())];
}


- (void)runRayTraceShade:(id<MTLCommandBuffer>)commandBuffer withInFlightIndex:(unsigned int)inFlight
{
    // the renderer uses its sub-renderers for shading (in particular the accumulation of the
    // sampling, so the logic is in the drawWithCommandBuffer.
}




- (void)drawWithCommandBuffer:(id<MTLCommandBuffer>)commandBuffer withInFlightIndex:(unsigned int)inFlight
{
    [self updateUniforms:inFlight];
    
    if ([self rayIntersect:commandBuffer withInFlightIndex:inFlight])
    {
        // generate rays for the two light sources
        //
        [self runRayTraceCompute:_shadowRayPipeline withCommandBuffer:commandBuffer
                   withParameter:@[_rayTraceUniform[inFlight],
                                   _randomBuffers[inFlight],
                                   _shadowRayBuffers[0],
                                   _shadowRayBuffers[1]]
                withIntersection:self.primaryIntersectionBuffer
               withInFlightIndex:inFlight];
        
        for (uint i = 0; i < 2; ++i)
        {
            // intersection detection for each light sources
            //
            [self rayIntersect:commandBuffer
                      withRays:_shadowRayBuffers[i] withIntersection:_shadowIntersectionBuffers[i]];
            
            // sub renderers accumulates the samplings
            //
            _subRenderers[i].rayStructure = self.rayStructure;
            _subRenderers[i].shadowRayBuffer = _shadowRayBuffers[i];
            _subRenderers[i].shadowIntersectionBuffer = _shadowIntersectionBuffers[i];
            [_subRenderers[i] drawWithCommandBuffer:commandBuffer withInFlightIndex:inFlight];
        }
    }
}


- (id<MTLTexture>)targetTextureForLightSource:(uint)index
{
    return _subRenderers[index].targetTexture;
}




@end
