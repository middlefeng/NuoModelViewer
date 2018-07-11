//
//  NuoRayTracingAccelerateStructure.m
//  ModelViewer
//
//  Created by middleware on 6/16/18.
//  Copyright © 2018 middleware. All rights reserved.
//

#import "NuoRayAccelerateStructure.h"
#import <MetalPerformanceShaders/MetalPerformanceShaders.h>

#import "NuoRayEmittor.h"
#import "NuoMesh.h"


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
        _intersector.rayDataType = MPSRayDataTypeOriginMinDistanceDirectionMaxDistance;
        _intersector.rayStride = kRayBufferStrid;
        
        /* not use mask as only mask is cared about for now */
        // _intersector.rayMaskOptions = MPSRayMaskOptionPrimitive;
        
        _accelerateStructure = [[MPSTriangleAccelerationStructure alloc] initWithDevice:commandQueue.device];
        _rayEmittor = [[NuoRayEmittor alloc] initWithCommandQueue:commandQueue];
        
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
    [_rayEmittor setDrawableSize:drawableSize];
}



- (CGSize)drawableSize
{
    return [_rayEmittor drawableSize];
}


- (VectorBuffer)positionBuffer:(NSArray<NuoMesh*>*)meshes
{
    VectorBuffer buffer;
    for (NuoMesh* mesh in meshes)
    {
        if (!mesh.enabled || mesh.hasTransparency)
            continue;
        
        VectorBuffer bufferForOne = [mesh worldPositionBuffer:NuoMatrixFloat44Identity];
        buffer.Union(bufferForOne);
    }
    
    return buffer;
}



- (VectorBuffer)normalBuffer:(NSArray<NuoMesh*>*)meshes
{
    VectorBuffer buffer;
    for (NuoMesh* mesh in meshes)
    {
        if (!mesh.enabled || mesh.hasTransparency)
            continue;
        
        VectorBuffer bufferForOne = [mesh worldNormalBuffer:NuoMatrixFloat44Identity];
        buffer.Union(bufferForOne);
    }
    
    return buffer;
}



- (void)setMeshes:(NSArray<NuoMesh*>*)meshes
{
    VectorBuffer buffer = [self positionBuffer:meshes];
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
    
    _accelerateStructure.vertexBuffer = vertexBufferPrivate;
    _accelerateStructure.indexType = MPSDataTypeUInt32;
    _accelerateStructure.indexBuffer = _indexBuffer;
    _accelerateStructure.triangleCount = triangleCount;
    
    VectorBuffer normalBufferContent = [self normalBuffer:meshes];
    id<MTLBuffer> normalBuffer = [_commandQueue.device newBufferWithBytes:&normalBufferContent._vertices[0]
                                                                   length:vertexBufferSize
                                                                  options:MTLResourceStorageModeShared];
    _normalBuffer = [_commandQueue.device newBufferWithLength:vertexBufferSize
                                                      options:MTLResourceStorageModePrivate];
    
    [encoder copyFromBuffer:normalBuffer sourceOffset:0
                   toBuffer:_normalBuffer destinationOffset:0 size:vertexBufferSize];
    
    [encoder endEncoding];
    [commandBuffer commit];
    
    [_accelerateStructure rebuild];
}


- (void)setView:(const NuoMatrixFloat44&)viewTrans
{
    [_rayEmittor setViewTrans:viewTrans.Inverse()];
}


- (void)rayTrace:(id<MTLCommandBuffer>)commandBuffer
        inFlight:(uint32_t)inFlight withIntersection:(id<MTLBuffer>)intersection
{
    if (_accelerateStructure.status == MPSAccelerationStructureStatusBuilt)
    {
        _primaryRayBuffer = [_rayEmittor rayBuffer:commandBuffer withInFlight:inFlight];
        
        [self rayTrace:commandBuffer
              withRays:_primaryRayBuffer withIntersection:intersection];
    }
}


- (void)rayTrace:(id<MTLCommandBuffer>)commandBuffer
        withRays:(id<MTLBuffer>)rayBuffer withIntersection:(id<MTLBuffer>)intersection
{
    if (_accelerateStructure.status == MPSAccelerationStructureStatusBuilt)
    {
        [_intersector setIntersectionDataType:MPSIntersectionDataTypeDistancePrimitiveIndexCoordinates];
        [_intersector encodeIntersectionToCommandBuffer:commandBuffer
                                       intersectionType:MPSIntersectionTypeNearest
                                              rayBuffer:rayBuffer
                                        rayBufferOffset:0
                                     intersectionBuffer:intersection
                               intersectionBufferOffset:0
                                               rayCount:[_rayEmittor rayCount]
                                  accelerationStructure:_accelerateStructure];
    }
}


- (id<MTLBuffer>)uniformBuffer:(uint32_t)inFlight
{
    return [_rayEmittor uniformBuffer:inFlight];
}




@end
