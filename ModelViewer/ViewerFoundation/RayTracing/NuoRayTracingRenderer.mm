//
//  NuoRayTracingRenderer.m
//  ModelViewer
//
//  Created by middleware on 6/11/18.
//  Copyright © 2018 middleware. All rights reserved.
//

#import "NuoRayTracingRenderer.h"
#import "NuoRayAccelerateStructure.h"

#import "NuoRayBuffer.h"
#import "NuoComputeEncoder.h"
#import "NuoArgumentBuffer.h"
#import "NuoTextureAverageMesh.h"
#import "NuoRenderPassAttachment.h"
#import "NuoCommandBuffer.h"

#import <MetalPerformanceShaders/MetalPerformanceShaders.h>



@interface NuoArgumentBufferKey : NSObject < NSCopying >

@property (assign) uint64_t pipeline;
@property (assign) uint64_t rayUniform;
@property (assign) uint64_t rayBuffer;
@property (assign) uint64_t intersectionBuffer;

@end


@implementation NuoArgumentBufferKey

- (id)copyWithZone:(nullable NSZone *)zone
{
    NuoArgumentBufferKey* newKey = [NuoArgumentBufferKey new];
    newKey.pipeline = _pipeline;
    newKey.rayUniform = _rayUniform;
    newKey.rayBuffer = _rayBuffer;
    newKey.intersectionBuffer = _intersectionBuffer;
    
    return newKey;
}

- (BOOL)isEqual:(id)other
{
    NuoArgumentBufferKey* otherKey = (NuoArgumentBufferKey*)other;
    
    return _pipeline == otherKey.pipeline &&
           _rayUniform == otherKey.rayUniform &&
           _rayBuffer == otherKey.rayBuffer &&
           _intersectionBuffer == otherKey.intersectionBuffer;
}


- (NSUInteger)hash
{
    return _pipeline + _rayUniform + _rayBuffer + _intersectionBuffer;
}

@end




@implementation NuoRayTracingRenderer
{
    NSArray<NuoTargetAccumulator*>* _accumulators;
    
    CGSize _drawableSize;
    
    id<MTLSamplerState> _sampleState;
    NSMutableDictionary<NuoArgumentBufferKey*, NuoArgumentBuffer*>* _rayStructUniform;
    NSMutableDictionary<NuoArgumentBufferKey*, NuoArgumentBuffer*>* _targetsUniform;
}



- (instancetype)initWithCommandQueue:(id<MTLCommandQueue>)commandQueue
                     withPixelFormat:(MTLPixelFormat)pixelFormat
                     withSampleCount:(uint)sampleCount
{
    assert(false);
}



- (instancetype)initWithCommandQueue:(id<MTLCommandQueue>)commandQueue
                     withPixelFormat:(MTLPixelFormat)pixelFormat
                     withTargetCount:(uint)targetCount
{
    self = [super initWithCommandQueue:commandQueue
                       withPixelFormat:MTLPixelFormatInvalid withSampleCount:1];
    
    if (self && targetCount > 0)
    {
        NuoTargetAccumulator* accumulators[targetCount];
        
        for (uint i = 0; i < targetCount; ++i)
        {
            accumulators[i] = [[NuoTargetAccumulator alloc] initWithCommandQueue:self.commandQueue
                                                                 withPixelFormat:pixelFormat
                                                                        withName:@"Ray Tracing"];
        }
        
        _accumulators = [[NSArray alloc] initWithObjects:accumulators count:targetCount];
        
        MTLSamplerDescriptor *samplerDesc = [MTLSamplerDescriptor new];
        samplerDesc.sAddressMode = MTLSamplerAddressModeRepeat;
        samplerDesc.tAddressMode = MTLSamplerAddressModeRepeat;
        samplerDesc.minFilter = MTLSamplerMinMagFilterLinear;
        samplerDesc.magFilter = MTLSamplerMinMagFilterLinear;
        samplerDesc.mipFilter = MTLSamplerMipFilterNotMipmapped;
        _sampleState = [commandQueue.device newSamplerStateWithDescriptor:samplerDesc];
        
        [self resetResources];
    }
    
    return self;
}



- (void)resetResources
{
    for (NuoTextureAccumulator* accumulator in _accumulators)
    {
        [accumulator reset];
    }
}



- (void)setDrawableSize:(CGSize)drawableSize
{
    [super setDrawableSize:drawableSize];
    
    if (!CGSizeEqualToSize(_drawableSize, drawableSize))
        _targetsUniform = [NSMutableDictionary new];
    
    for (NuoTargetAccumulator* accumulator in _accumulators)
        [accumulator setDrawableSize:drawableSize];
    
    const uint w = (uint)drawableSize.width;
    const uint h = (uint)drawableSize.height;
    const uint intersectionSize = kRayIntersectionStride * w * h;
    _intersectionBuffer = [self.commandQueue.device newBufferWithLength:intersectionSize
                                                                options:MTLResourceStorageModePrivate];
    
    _drawableSize = drawableSize;
}



- (void)updatePrimaryRayMask:(uint32)mask withCommandBuffer:(NuoCommandBuffer*)commandBuffer
{
    [_rayStructure updatePrimaryRayMask:mask withCommandBuffer:commandBuffer];
}


- (void)primaryRayEmit:(NuoCommandBuffer*)commandBuffer
{
    [_rayStructure primaryRayEmit:commandBuffer];
}


- (BOOL)primaryRayIntersect:(NuoCommandBuffer*)commandBuffer
{
    if (!_rayStructure || !_rayStructure.vertexBuffer)
        return NO;
    
    [_rayStructure primaryRayIntersect:commandBuffer withIntersection:_intersectionBuffer];
    return YES;
}


- (BOOL)rayIntersect:(NuoCommandBuffer*)commandBuffer
            withRays:(NuoRayBuffer*)rayBuffer withIntersection:(id<MTLBuffer>)intersection
{
    if (!_rayStructure)
        return NO;
    
    [_rayStructure rayIntersect:commandBuffer withRays:rayBuffer withIntersection:intersection];
    return YES;
}


- (void)runRayTraceCompute:(NuoComputePipeline*)pipeline
         withCommandBuffer:(NuoCommandBuffer*)commandBuffer
               withTargets:(BOOL)withTargets
             withParameter:(NSArray<id<MTLBuffer>>*)paramterBuffers
            withExitantRay:(id<MTLBuffer>)exitantRay
          withIntersection:(id<MTLBuffer>)intersection
{
    NuoComputeEncoder* computeEncoder = [pipeline encoderWithCommandBuffer:commandBuffer];
    id<MTLBuffer> effectiveRay = exitantRay ? exitantRay : [_rayStructure primaryRayBuffer].buffer;
    
    uint i = 0;

    NuoArgumentBuffer* argumentBuffer = [self raystructUniform:pipeline
                                                  withInFlight:commandBuffer
                                                withExitantRay:effectiveRay
                                              withIntersection:intersection];
    [computeEncoder setArgumentBuffer:argumentBuffer];
    
    if (withTargets)
    {
        NuoArgumentBuffer* targetBuffer = [self targetsUniform:pipeline];
        [computeEncoder setArgumentBuffer:targetBuffer];
        ++i;
    }
    
    if (paramterBuffers)
    {
        for (id<MTLBuffer> param in paramterBuffers)
            [computeEncoder setBuffer:param offset:0 atIndex:++i];
    }
    
    uint targetIndex = 0;
    for (id<MTLTexture> diffuseTexture in _rayStructure.diffuseTextures)
    {
        [computeEncoder setTexture:diffuseTexture atIndex:targetIndex];
        targetIndex += 1;
    }
    
    [computeEncoder setSamplerState:_sampleState atIndex:0];
    [computeEncoder setDataSize:_drawableSize];
    [computeEncoder dispatch];
}



- (void)runRayTraceCompute:(NuoComputePipeline*)pipeline
         withCommandBuffer:(NuoCommandBuffer*)commandBuffer
             withParameter:(NSArray<id<MTLBuffer>>*)paramterBuffers
            withExitantRay:(id<MTLBuffer>)exitantRay
          withIntersection:(id<MTLBuffer>)intersection
{
    [self runRayTraceCompute:pipeline
           withCommandBuffer:commandBuffer
                 withTargets:YES withParameter:paramterBuffers
              withExitantRay:exitantRay withIntersection:intersection];
}


- (void)runRayTraceCompute:(NuoComputePipeline*)pipeline
         withCommandBuffer:(NuoCommandBuffer*)commandBuffer
             withParameter:(NSArray<id<MTLBuffer>>*)paramterBuffers
          withIntersection:(id<MTLBuffer>)intersection
{
    [self runRayTraceCompute:pipeline withCommandBuffer:commandBuffer
               withParameter:paramterBuffers withExitantRay:nil withIntersection:intersection];
}


- (void)runRayTraceCompute:(NuoComputePipeline*)pipeline
         withCommandBuffer:(NuoCommandBuffer*)commandBuffer
             withParameter:(NSArray<id<MTLBuffer>>*)paramterBuffers
{
    [self runRayTraceCompute:pipeline withCommandBuffer:commandBuffer
               withParameter:paramterBuffers withIntersection:self.intersectionBuffer];
}



- (void)runRayTraceShade:(NuoCommandBuffer*)commandBuffer
{
    /* default behavior is not very useful, meant to be override */
    
    /*************************************************************/
    /*************************************************************/
    if ([self primaryRayIntersect:commandBuffer])
    {
        [self runRayTraceCompute:/* some shade pipeline */ nil withCommandBuffer:commandBuffer
                   withParameter:nil withExitantRay:nil withIntersection:nil];
    }
    /*************************************************************/
    /*************************************************************/
}



- (void)drawWithCommandBuffer:(NuoCommandBuffer*)commandBuffer
{
    // clear the ray tracing target
    //
    for (NuoTargetAccumulator* accumulator in _accumulators)
        [accumulator clearRenderTargetWithCommandBuffer:commandBuffer];
    
    [self runRayTraceShade:commandBuffer];
    
    for (NuoTargetAccumulator* accumulator in _accumulators)
        [accumulator accumulateWithCommandBuffer:commandBuffer];
}



- (NSArray<id<MTLTexture>>*)targetTextures
{
    id<MTLTexture> textures[_accumulators.count];
    for (uint i = 0; i < _accumulators.count; ++i)
        textures[i] = _accumulators[i].accumulateTarget.targetTexture;
    
    return [[NSArray alloc] initWithObjects:textures count:_accumulators.count];
}



- (void)rayStructUpdated
{
    _rayStructUniform = [NSMutableDictionary new];
}



- (NuoArgumentBuffer*)raystructUniform:(NuoComputePipeline*)pipeline
                          withInFlight:(id<NuoRenderInFlight>)inFlight
                        withExitantRay:(id<MTLBuffer>)exitantRay
                      withIntersection:(id<MTLBuffer>)intersection
{
    id<MTLBuffer> uniform = [_rayStructure uniformBuffer:inFlight];
    
    NuoArgumentBufferKey* key = [NuoArgumentBufferKey new];
    key.rayUniform = (uint64_t)uniform;
    key.pipeline = (uint64_t)pipeline;
    key.rayBuffer = (uint64_t)exitantRay;
    
    NuoArgumentBuffer* buffer = [_rayStructUniform objectForKey:key];
    
    if (buffer)
        return buffer;
    
    id<MTLArgumentEncoder> encoder = [pipeline argumentEncoder:0];
    buffer = [NuoArgumentBuffer new];
    
    uint i = 0;
    [buffer encodeWith:encoder forIndex:0];
    [buffer setBuffer:uniform for:MTLResourceUsageRead atIndex:i];
    [buffer setBuffer:[_rayStructure indexBuffer] for:MTLResourceUsageRead atIndex:++i];
    [buffer setBuffer:[_rayStructure maskBuffer] for:MTLResourceUsageRead atIndex:++i];
    [buffer setBuffer:[_rayStructure materialBuffer] for:MTLResourceUsageRead atIndex:++i];
    [buffer setBuffer:exitantRay for:MTLResourceUsageRead | MTLResourceUsageWrite atIndex:++i];
    [buffer setBuffer:intersection for:MTLResourceUsageRead atIndex:++i];
    
    [_rayStructUniform setObject:buffer forKey:key];
    
    return buffer;
}


- (NuoArgumentBuffer*)targetsUniform:(NuoComputePipeline*)pipeline
{
    NuoArgumentBufferKey* key = [NuoArgumentBufferKey new];
    key.pipeline = (uint64_t)pipeline;
    
    NuoArgumentBuffer* buffer = [_targetsUniform objectForKey:key];
    
    if (buffer)
        return buffer;
    
    id<MTLArgumentEncoder> encoder = [pipeline argumentEncoder:1];
    buffer = [NuoArgumentBuffer new];
    [buffer encodeWith:encoder forIndex:1];
    
    uint i = 0;
    for (NuoTargetAccumulator* accumulator in _accumulators)
    {
        [buffer setTexture:accumulator.renderTarget.targetTexture
                       for:(MTLTextureUsageShaderRead | MTLTextureUsageShaderWrite)
                   atIndex:i++];
    }
    
    [_targetsUniform setObject:buffer forKey:key];
    return buffer;
}



@end
