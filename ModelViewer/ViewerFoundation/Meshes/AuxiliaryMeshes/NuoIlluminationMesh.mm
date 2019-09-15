//
//  NuoIlluminationMesh.m
//  ModelViewer
//
//  Created by middleware on 8/27/18.
//  Copyright © 2018 middleware. All rights reserved.
//

#import "NuoIlluminationMesh.h"



@implementation NuoIlluminationTarget

@end




@implementation NuoIlluminationMesh
{
    id<MTLBuffer> _paramBuffer;
}


- (instancetype)initWithCommandQueue:(id<MTLCommandQueue>)commandQueue
{
    self = [super initWithCommandQueue:commandQueue];
    
    if (self)
    {
        _paramBuffer = [commandQueue.device newBufferWithLength:sizeof(NuoVectorFloat3::_vector)
                                                        options:MTLResourceStorageModeManaged];
    }
    
    return self;
}


- (void)makePipelineAndSampler:(MTLPixelFormat)pixelFormat
                 withBlendMode:(ScreenSpaceBlendMode)blendMode
                    withHybrid:(BOOL)hybrid
{
    NSString* shaderName = hybrid? @"illumination_blend_hybrid" : @"illumination_blend";
    
    [self makePipelineAndSampler:pixelFormat withFragementShader:shaderName
                   withBlendMode:blendMode];
}



- (void)setAmbient:(const NuoVectorFloat3&)ambient
{
    memcpy(_paramBuffer.contents, &ambient._vector, sizeof(NuoVectorFloat3::_vector));
    [_paramBuffer didModifyRange:NSMakeRange(0, sizeof(NuoVectorFloat3::_vector))];
}



- (void)drawMesh:(NuoRenderPassEncoder*)renderPass
{
    [renderPass pushParameterState:@"Illumination"];
    
    [self setModelTexture:_illuminations.normal];
    [renderPass setFragmentTexture:_illuminations.ambientNormal atIndex:1];
    [renderPass setFragmentTexture:_illuminations.ambientVirtual atIndex:2];
    [renderPass setFragmentTexture:_illuminations.directVirtual atIndex:3];
    [renderPass setFragmentTexture:_illuminations.directVirtualBlocked atIndex:4];
    
    if (_translucentCoverMap)
        [renderPass setFragmentTexture:_translucentCoverMap atIndex:5];
    
    [renderPass setFragmentBuffer:_paramBuffer offset:0 atIndex:0];
    [super drawMesh:renderPass];
    
    [renderPass popParameterState];
}


@end
