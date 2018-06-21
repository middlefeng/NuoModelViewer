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
    
    // TODO: debug
    id<MTLComputePipelineState> _shadePipeline;
}


- (instancetype)initWithQueue:(id<MTLCommandQueue>)queue
{
    self = [super init];
    
    if (self)
    {
        _intersector = [[MPSRayIntersector alloc] initWithDevice:queue.device];
        _intersector.rayDataType = MPSRayDataTypeOriginMaskDirectionMaxDistance;
        _intersector.rayStride = kRayBufferStrid;
        
        /* not use mask as only mask is cared about for now */
        // _intersector.rayMaskOptions = MPSRayMaskOptionPrimitive;
        
        _accelerateStructure = [[MPSTriangleAccelerationStructure alloc] initWithDevice:queue.device];
        
        _rayEmittor = [[NuoRayEmittor alloc] initWithCommandQueue:queue];
        
        NSError* error = nil;
        MTLFunctionConstantValues* values = [MTLFunctionConstantValues new];
        id<MTLLibrary> library = [queue.device newDefaultLibrary];
        id<MTLFunction> shadeFunction = [library newFunctionWithName:@"shade_function" constantValues:values error:&error];
        assert(error == nil);
        
        _shadePipeline = [queue.device newComputePipelineStateWithFunction:shadeFunction error:&error];
        assert(error == nil);
        
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
        toTarget:(NuoRenderPassTarget*)renderTarget
{
    if (_accelerateStructure.status == MPSAccelerationStructureStatusBuilt)
    {
        id<MTLBuffer> rayBuffer = [_rayEmittor rayBuffer:commandBuffer withInFlight:inFlight
                                                toTarget:renderTarget];
        
        [_intersector setIntersectionDataType:MPSIntersectionDataTypeDistancePrimitiveIndexCoordinates];
        [_intersector encodeIntersectionToCommandBuffer:commandBuffer
                                       intersectionType:MPSIntersectionTypeNearest
                                              rayBuffer:rayBuffer
                                        rayBufferOffset:0
                                     intersectionBuffer:_intersectionBuffer
                               intersectionBufferOffset:0
                                               rayCount:[_rayEmittor rayCount]
                                  accelerationStructure:_accelerateStructure];
        
        id<MTLComputeCommandEncoder> computeEncoder = [commandBuffer computeCommandEncoder];
        [computeEncoder setBuffer:[_rayEmittor uniformBuffer:inFlight] offset:0 atIndex:0];
        [computeEncoder setBuffer:_intersectionBuffer offset:0 atIndex:1];
        [computeEncoder setTexture:renderTarget.targetTexture atIndex:0];
        [computeEncoder setComputePipelineState:_shadePipeline];
        
        const float w = _rayEmittor.drawableSize.width;
        const float h = _rayEmittor.drawableSize.height;
        MTLSize threads = MTLSizeMake(8, 8, 1);
        MTLSize threadgroups = MTLSizeMake((w + threads.width  - 1) / threads.width,
                                           (h + threads.height - 1) / threads.height, 1);
        [computeEncoder dispatchThreadgroups:threadgroups threadsPerThreadgroup:threads];
        
        [computeEncoder endEncoding];
    }
}


@end
