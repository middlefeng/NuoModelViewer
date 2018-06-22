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
    id<MTLBuffer> _intersectionBuffer;
    
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
    
    const uint w = (uint)drawableSize.width;
    const uint h = (uint)drawableSize.height;
    const uint intersectionSize = kRayIntersectionStrid * w * h;
    _intersectionBuffer = [_device newBufferWithLength:intersectionSize options:MTLResourceStorageModePrivate];
}



- (CGSize)drawableSize
{
    return [_rayEmittor drawableSize];
}


- (PositionBuffer)positionBuffer:(NSArray<NuoMesh*>*)meshes
{
    PositionBuffer buffer;
    for (NuoMesh* mesh in meshes)
    {
        PositionBuffer bufferForOne = [mesh worldPositionBuffer:NuoMatrixFloat44Identity];
        buffer.insert(buffer.end(), bufferForOne.begin(), bufferForOne.end());
    }
    
    return buffer;
}



- (void)setMeshes:(NSArray<NuoMesh*>*)meshes
{
    PositionBuffer buffer = [self positionBuffer:meshes];
    uint32_t triangleCount = (uint32_t)buffer.size() / 3;
    
    id<MTLBuffer> vertexBuffer = [_device newBufferWithBytes:&buffer[0]
                                                      length:buffer.size() * sizeof(NuoVectorFloat3::_typeTrait::_vectorType)
                                                     options:MTLResourceStorageModeShared];
    
    _accelerateStructure.vertexBuffer = vertexBuffer;
    _accelerateStructure.triangleCount = triangleCount;
    
    [_accelerateStructure rebuild];
}


- (void)setView:(const NuoMatrixFloat44&)viewTrans
{
    [_rayEmittor setViewTrans:viewTrans.Inverse()];
}


- (void)rayTrace:(id<MTLCommandBuffer>)commandBuffer inFlight:(uint32_t)inFlight
{
    if (_accelerateStructure.status == MPSAccelerationStructureStatusBuilt)
    {
        id<MTLBuffer> rayBuffer = [_rayEmittor rayBuffer:commandBuffer withInFlight:inFlight];
        
        [_intersector setIntersectionDataType:MPSIntersectionDataTypeDistancePrimitiveIndexCoordinates];
        [_intersector encodeIntersectionToCommandBuffer:commandBuffer
                                       intersectionType:MPSIntersectionTypeNearest
                                              rayBuffer:rayBuffer
                                        rayBufferOffset:0
                                     intersectionBuffer:_intersectionBuffer
                               intersectionBufferOffset:0
                                               rayCount:[_rayEmittor rayCount]
                                  accelerationStructure:_accelerateStructure];
    }
}


- (id<MTLBuffer>)uniformBuffer:(uint32_t)inFlight
{
    return [_rayEmittor uniformBuffer:inFlight];
}


- (id<MTLBuffer>)intersectionBuffer
{
    return _intersectionBuffer;
}


@end
