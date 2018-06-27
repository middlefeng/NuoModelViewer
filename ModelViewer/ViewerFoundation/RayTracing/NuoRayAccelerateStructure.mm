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


const uint kRayIntersectionStrid = sizeof(MPSIntersectionDistancePrimitiveIndexCoordinates);



@implementation NuoRayAccelerateStructure
{
    id<MTLDevice> _device;
    
    MPSRayIntersector* _intersector;
    MPSTriangleAccelerationStructure* _accelerateStructure;
    
    NuoRayEmittor* _rayEmittor;
}


- (instancetype)initWithQueue:(id<MTLCommandQueue>)queue
{
    self = [super init];
    
    if (self)
    {
        _intersector = [[MPSRayIntersector alloc] initWithDevice:queue.device];
        _intersector.rayDataType = MPSRayDataTypeOriginMinDistanceDirectionMaxDistance;
        _intersector.rayStride = kRayBufferStrid;
        
        /* not use mask as only mask is cared about for now */
        // _intersector.rayMaskOptions = MPSRayMaskOptionPrimitive;
        
        _accelerateStructure = [[MPSTriangleAccelerationStructure alloc] initWithDevice:queue.device];
        _rayEmittor = [[NuoRayEmittor alloc] initWithCommandQueue:queue];
        
        _device = queue.device;
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
        VectorBuffer bufferForOne = [mesh worldPositionBuffer:NuoMatrixFloat44Identity];
        buffer.Union(bufferForOne);
    }
    
    return buffer;
}



- (void)setMeshes:(NSArray<NuoMesh*>*)meshes
{
    VectorBuffer buffer = [self positionBuffer:meshes];
    uint32_t triangleCount = (uint32_t)buffer._indices.size() / 3;
    
    id<MTLBuffer> vertexBuffer = [_device newBufferWithBytes:&buffer._vertices[0]
                                                      length:buffer._vertices.size() * sizeof(NuoVectorFloat3::_typeTrait::_vectorType)
                                                     options:MTLResourceStorageModeShared];
    id<MTLBuffer> indexBuffer = [_device newBufferWithBytes:&buffer._indices[0]
                                                      length:buffer._indices.size() * sizeof(uint32)
                                                     options:MTLResourceStorageModeShared];
    
    _accelerateStructure.vertexBuffer = vertexBuffer;
    _accelerateStructure.indexType = MPSDataTypeUInt32;
    _accelerateStructure.indexBuffer = indexBuffer;
    _accelerateStructure.triangleCount = triangleCount;
    
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
