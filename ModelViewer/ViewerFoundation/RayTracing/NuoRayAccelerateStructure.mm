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
    VectorBuffer buffer = [root worldPositionBuffer:NuoMatrixFloat44Identity];
    uint32_t triangleCount = (uint32_t)buffer._indices.size() / 3;
    uint32_t vertexBufferSize = (uint32_t)(buffer._vertices.size() * sizeof(NuoVectorFloat3::_typeTrait::_vectorType));
    uint32_t indexBufferSize = (uint32_t)(buffer._indices.size() * sizeof(uint32));
    
    id<MTLBuffer> vertexBuffer = [_commandQueue.device newBufferWithBytes:&buffer._vertices[0]
                                                                   length:vertexBufferSize
                                                                  options:MTLResourceStorageModeShared];
    id<MTLBuffer> indexBuffer = [_commandQueue.device newBufferWithBytes:&buffer._indices[0]
                                                                  length:indexBufferSize
                                                                 options:MTLResourceStorageModeShared];
    
    id<MTLBuffer> vertexBufferPrivate = [_commandQueue.device newBufferWithLength:vertexBufferSize
                                                                          options:MTLResourceStorageModePrivate];
    _indexBuffer = [_commandQueue.device newBufferWithLength:indexBufferSize
                                                     options:MTLResourceStorageModePrivate];
    
    id<MTLCommandBuffer> commandBuffer = [_commandQueue commandBuffer];
    id<MTLBlitCommandEncoder> encoder = [commandBuffer blitCommandEncoder];
    
    [encoder copyFromBuffer:vertexBuffer sourceOffset:0
                   toBuffer:vertexBufferPrivate destinationOffset:0 size:vertexBufferSize];
    [encoder copyFromBuffer:indexBuffer sourceOffset:0
                   toBuffer:_indexBuffer destinationOffset:0 size:indexBufferSize];
    
    VectorBuffer normalBufferContent = [root worldNormalBuffer:NuoMatrixFloat44Identity];
    id<MTLBuffer> normalBuffer = [_commandQueue.device newBufferWithBytes:&normalBufferContent._vertices[0]
                                                                   length:vertexBufferSize
                                                                  options:MTLResourceStorageModeShared];
    _normalBuffer = [_commandQueue.device newBufferWithLength:vertexBufferSize
                                                      options:MTLResourceStorageModePrivate];
    
    [encoder copyFromBuffer:normalBuffer sourceOffset:0
                   toBuffer:_normalBuffer destinationOffset:0 size:vertexBufferSize];
    
    std::vector<uint32_t> mask = [root maskBuffer];
    uint32_t maskBufferSize =(uint32_t)(mask.size() * sizeof(uint32_t));
    id<MTLBuffer> maskBuffer = [_commandQueue.device newBufferWithBytes:&mask[0]
                                                                 length:maskBufferSize
                                                                options:MTLResourceStorageModeShared];
    _maskBuffer = [_commandQueue.device newBufferWithLength:maskBufferSize
                                                    options:MTLResourceStorageModePrivate];
    
    [encoder copyFromBuffer:maskBuffer sourceOffset:0
                   toBuffer:_maskBuffer destinationOffset:0 size:maskBufferSize];
    
    [encoder endEncoding];
    [commandBuffer commit];
    
    _accelerateStructure.vertexBuffer = vertexBufferPrivate;
    _accelerateStructure.indexType = MPSDataTypeUInt32;
    _accelerateStructure.indexBuffer = _indexBuffer;
    _accelerateStructure.triangleCount = triangleCount;
    _accelerateStructure.maskBuffer = _maskBuffer;
    
    [_accelerateStructure rebuild];
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
