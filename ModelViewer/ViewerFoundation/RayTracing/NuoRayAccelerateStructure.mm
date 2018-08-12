//
//  NuoRayTracingAccelerateStructure.m
//  ModelViewer
//
//  Created by middleware on 6/16/18.
//  Copyright © 2018 middleware. All rights reserved.
//

#import "NuoRayAccelerateStructure.h"
#import <MetalPerformanceShaders/MetalPerformanceShaders.h>

#import "NuoRayBuffer.h"
#import "NuoRayEmittor.h"
#import "NuoMeshSceneRoot.h"

#include "NuoRayTracingUniform.h"


const uint kRayIntersectionStride = sizeof(MPSIntersectionDistancePrimitiveIndexCoordinates);



@implementation NuoRayAccelerateStructure
{
    id<MTLCommandQueue> _commandQueue;
    
    MPSRayIntersector* _intersector;
    MPSTriangleAccelerationStructure* _accelerateStructure;
    
    NuoRayEmittor* _rayEmittor;
}


- (instancetype)initWithCommandQueue:(id<MTLCommandQueue>)commandQueue
{
    self = [super init];
    
    if (self)
    {
        _intersector = [[MPSRayIntersector alloc] initWithDevice:commandQueue.device];
        _intersector.rayDataType = MPSRayDataTypeOriginMaskDirectionMaxDistance;
        _intersector.rayStride = kRayBufferStrid;
        _intersector.rayMaskOptions = MPSRayMaskOptionPrimitive;
        
        _accelerateStructure = [[MPSTriangleAccelerationStructure alloc] initWithDevice:commandQueue.device];
        _accelerateStructure.usage = MPSAccelerationStructureUsageRefit;
        
        _rayEmittor = [[NuoRayEmittor alloc] initWithCommandQueue:commandQueue];
        _primaryRayBuffer = [[NuoRayBuffer alloc] initWithDevice:commandQueue.device];
        
        _commandQueue = commandQueue;
    }
    
    return self;
}


- (void)setFieldOfView:(CGFloat)fieldOfView
{
    [_rayEmittor setFieldOfView:fieldOfView];
}


- (CGFloat)fieldOfView
{
    return [_rayEmittor fieldOfView];
}



- (void)setDrawableSize:(CGSize)drawableSize
{
    [_primaryRayBuffer setDimension:drawableSize];
}



- (CGSize)drawableSize
{
    return [_primaryRayBuffer dimension];
}



- (void)setRoot:(NuoMeshSceneRoot*)root
{
    // all coordinates are in the world system, with primary rays following the same rule as
    // they are transformed through the inverse of the view matrix
    
    GlobalBuffers buffer = [root worldBuffers:NuoMatrixFloat44Identity];
    uint32_t triangleCount = (uint32_t)buffer._indices.size() / 3;
    uint32_t indexBufferSize = (uint32_t)(buffer._indices.size() * sizeof(uint32));
    
    id<MTLBuffer> indexBuffer = [_commandQueue.device newBufferWithBytes:&buffer._indices[0]
                                                                  length:indexBufferSize
                                                                 options:MTLResourceStorageModeShared];
    
    _indexBuffer = [_commandQueue.device newBufferWithLength:indexBufferSize
                                                     options:MTLResourceStorageModePrivate];
    
    id<MTLCommandBuffer> commandBuffer = [_commandQueue commandBuffer];
    id<MTLBlitCommandEncoder> encoder = [commandBuffer blitCommandEncoder];
    
    [encoder copyFromBuffer:indexBuffer sourceOffset:0
                   toBuffer:_indexBuffer destinationOffset:0 size:indexBufferSize];
    
    _materialBuffer = nil;
    _vertexBuffer = nil;
    _maskBuffer = nil;
    
    [self setWorldBuffers:buffer];
    [self setMaskBuffer:root];
    
    [encoder endEncoding];
    [commandBuffer commit];
    [commandBuffer waitUntilCompleted];
    
    _accelerateStructure.vertexBuffer = _vertexBuffer;
    _accelerateStructure.indexType = MPSDataTypeUInt32;
    _accelerateStructure.indexBuffer = _indexBuffer;
    _accelerateStructure.triangleCount = triangleCount;
    _accelerateStructure.maskBuffer = _maskBuffer;
    
    [_accelerateStructure rebuild];
}


- (void)setRoot:(NuoMeshSceneRoot *)root withCommandBuffer:(id<MTLCommandBuffer>)commandBuffer
{
    assert(_maskBuffer != nil);
    assert(_vertexBuffer != nil);
    assert(_materialBuffer != nil);
    
    GlobalBuffers buffer = [root worldBuffers:NuoMatrixFloat44Identity];
    
    [self setWorldBuffers:buffer];
    [self setMaskBuffer:root];
    [_accelerateStructure encodeRefitToCommandBuffer:commandBuffer];
}



- (void)setWorldBuffers:(const GlobalBuffers&)buffers
{
    uint32_t vertexBufferSize = (uint32_t)(buffers._vertices.size() * sizeof(NuoVectorFloat3::_typeTrait::_vectorType));
    uint32_t materialBufferSize = (uint32_t)(buffers._vertices.size() * sizeof(NuoRayTracingMaterial));
    
    if (!_materialBuffer)
    {
        _materialBuffer = [_commandQueue.device newBufferWithLength:materialBufferSize
                                                            options:MTLResourceStorageModeManaged];
    }
    
    memcpy(_materialBuffer.contents, &buffers._materials[0], materialBufferSize);
    [_materialBuffer didModifyRange:NSMakeRange(0, materialBufferSize)];
     
     if (!_vertexBuffer)
     {
         _vertexBuffer = [_commandQueue.device newBufferWithLength:vertexBufferSize
                                                           options:MTLResourceStorageModeManaged];
     }
     
     memcpy(_vertexBuffer.contents, &buffers._vertices[0], vertexBufferSize);
     [_vertexBuffer didModifyRange:NSMakeRange(0, vertexBufferSize)];
}

    
- (void)setMaskBuffer:(NuoMeshSceneRoot*)root
{
    std::vector<uint32_t> mask = [root maskBuffer];
    uint32_t maskBufferSize = (uint32_t)(mask.size() * sizeof(uint32_t));
    
    if (!_maskBuffer)
    {
        _maskBuffer = [_commandQueue.device newBufferWithLength:maskBufferSize
                                                      options:MTLResourceStorageModeManaged];
    }
    
    memcpy(_maskBuffer.contents, &mask[0], maskBufferSize);
    [_maskBuffer didModifyRange:NSMakeRange(0, maskBufferSize)];
}


- (void)setView:(const NuoMatrixFloat44&)viewTrans
{
    [_rayEmittor setViewTrans:viewTrans.Inverse()];
}


- (void)updateRayMask:(uint32)mask withCommandBuffer:(id<MTLCommandBuffer>)commandBuffer
         withInFlight:(uint)inFlight
{
    [_primaryRayBuffer updateRayMask:mask withUniform:[self uniformBuffer:inFlight]
                                    withCommandBuffer:commandBuffer];
}


- (void)rayEmit:(id<MTLCommandBuffer>)commandBuffer inFlight:(uint32_t)inFlight
{
    [_rayEmittor rayEmitToBuffer:_primaryRayBuffer withCommandBuffer:commandBuffer withInFlight:inFlight];
}


- (void)rayTrace:(id<MTLCommandBuffer>)commandBuffer
        inFlight:(uint32_t)inFlight withIntersection:(id<MTLBuffer>)intersection
{
    if (_accelerateStructure.status == MPSAccelerationStructureStatusBuilt)
    {
        [self rayTrace:commandBuffer
              withRays:_primaryRayBuffer withIntersection:intersection];
    }
}


- (void)rayTrace:(id<MTLCommandBuffer>)commandBuffer
        withRays:(NuoRayBuffer*)rayBuffer withIntersection:(id<MTLBuffer>)intersection
{
    if (_accelerateStructure.status == MPSAccelerationStructureStatusBuilt)
    {
        [_intersector setIntersectionDataType:MPSIntersectionDataTypeDistancePrimitiveIndexCoordinates];
        [_intersector encodeIntersectionToCommandBuffer:commandBuffer
                                       intersectionType:MPSIntersectionTypeNearest
                                              rayBuffer:rayBuffer.buffer
                                        rayBufferOffset:0
                                     intersectionBuffer:intersection
                               intersectionBufferOffset:0
                                               rayCount:rayBuffer.rayCount
                                  accelerationStructure:_accelerateStructure];
    }
}


- (id<MTLBuffer>)uniformBuffer:(uint32_t)inFlight
{
    return [_rayEmittor uniformBuffer:inFlight];
}




@end
