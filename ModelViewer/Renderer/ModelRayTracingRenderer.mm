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

#include "NuoRandomBuffer.h"

#include <simd/simd.h>


@implementation ModelRayTracingRenderer
{
    id<MTLComputePipelineState> _shadowRayPipeline;
    id<MTLComputePipelineState> _shadowShadePipeline;
    
    NSArray<id<MTLBuffer>>* _rayTraceUniform;
    
    CGSize _shadowBufferSize;
    NSArray<id<MTLBuffer>>* _shadowRayBuffers;
    NSArray<id<MTLBuffer>>* _randomBuffers;
    NSArray<id<MTLBuffer>>* _shadowIntersectionBuffers;
}


- (instancetype)initWithCommandQueue:(id<MTLCommandQueue>)commandQueue
                     withPixelFormat:(MTLPixelFormat)pixelFormat
                     withSampleCount:(uint)sampleCount
{
    self = [super initWithCommandQueue:commandQueue
                       withPixelFormat:pixelFormat withSampleCount:1];
    if (self)
    {
        NSError* error = nil;
        MTLFunctionConstantValues* values = [MTLFunctionConstantValues new];
        id<MTLLibrary> library = [commandQueue.device newDefaultLibrary];
        
        id<MTLFunction> shadowRayFunction = [library newFunctionWithName:@"shadow_ray_emit" constantValues:values error:&error];
        assert(error == nil);
        _shadowRayPipeline = [commandQueue.device newComputePipelineStateWithFunction:shadowRayFunction error:&error];
        assert(error == nil);
        
        id<MTLFunction> shadowShadeFunction = [library newFunctionWithName:@"shadow_shade" constantValues:values error:&error];
        assert(error == nil);
        _shadowShadePipeline = [commandQueue.device newComputePipelineStateWithFunction:shadowShadeFunction error:&error];
        assert(error == nil);
        
        id<MTLBuffer> buffers[kInFlightBufferCount];
        id<MTLBuffer> randoms[kInFlightBufferCount];
        NuoRandomBuffer<NuoVectorFloat2::_typeTrait::_vectorType> randomBufferContent(256);
        for (uint i = 0; i < kInFlightBufferCount; ++i)
        {
            buffers[i] = [commandQueue.device newBufferWithLength:sizeof(NuoRayTracingUniforms)
                                                          options:MTLResourceStorageModeManaged];
            randoms[i] = [commandQueue.device newBufferWithLength:256 * sizeof(simd::float2)
                                                          options:MTLResourceStorageModeManaged];
        }
        _rayTraceUniform = [[NSArray alloc] initWithObjects:buffers count:kInFlightBufferCount];
        _randomBuffers = [[NSArray alloc] initWithObjects:randoms count:kInFlightBufferCount];
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
    }
    
    _shadowRayBuffers = [[NSArray alloc] initWithObjects:shadowRayBuffers count:2];
    _shadowIntersectionBuffers = [[NSArray alloc] initWithObjects:shadowIntersections count:2];
    _shadowBufferSize = drawableSize;
}


- (void)updateUniforms:(uint32_t)index
{
    NuoRayTracingUniforms uniforms;
    
    for (uint i = 0; i < 2; ++i)
    {
        const NuoMatrixFloat44& lightDriection = [[_paramsProvider shadowMapRenderer:i] lightDirectionMatrix];
        uniforms.lightSources[i] = lightDriection._m;
    }
    
    NuoBounds bounds = [_paramsProvider sceneBounds];
    uniforms.bounds.span = bounds.MaxDimension();
    uniforms.bounds.center = NuoVectorFloat4(bounds._center._vector.x, bounds._center._vector.y, bounds._center._vector.z, 1.0)._vector;
    
    memcpy(_rayTraceUniform[index].contents, &uniforms, sizeof(NuoRayTracingUniforms));
    [_rayTraceUniform[index] didModifyRange:NSMakeRange(0, sizeof(NuoRayTracingUniforms))];
    
    //NuoRandomBuffer<NuoVectorFloat2::_typeTrait::_vectorType> randomBuffer(256);
    //memcpy([_randomBuffers[index] contents], randomBuffer.Ptr(), randomBuffer.BytesSize());
    
    simd::float2* random = (simd::float2*)[_randomBuffers[index] contents];
    for (int i = 0; i < 256; i++)
        random[i] = {
            /*(float)(index % 3) / 2.0f,*/(float)rand() / (float)RAND_MAX,
            (float)rand() / (float)RAND_MAX
        };
    
    [_randomBuffers[index] didModifyRange:NSMakeRange(0, 256 * sizeof(simd::float2))];
}


- (void)runRayTraceShade:(id<MTLCommandBuffer>)commandBuffer withInFlightIndex:(unsigned int)inFlight
{
    [self updateUniforms:inFlight];
    
    if ([self rayIntersect:commandBuffer withInFlightIndex:inFlight])
    {
        [self runRayTraceCompute:_shadowRayPipeline withCommandBuffer:commandBuffer
                   withParameter:@[_rayTraceUniform[inFlight],
                                   _randomBuffers[inFlight],
                                   _shadowRayBuffers[0],
                                   _shadowRayBuffers[1]]
                withIntersection:self.primaryIntersectionBuffer
               withInFlightIndex:inFlight];
        
        for (uint i = 0; i < 2; ++i)
        {
            [self rayIntersect:commandBuffer
                      withRays:_shadowRayBuffers[i] withIntersection:_shadowIntersectionBuffers[i]];
        }
        
        [self runRayTraceCompute:_shadowShadePipeline withCommandBuffer:commandBuffer
                   withParameter:@[_shadowRayBuffers[0]]
                withIntersection:_shadowIntersectionBuffers[0] withInFlightIndex:inFlight];
    }
}




@end
