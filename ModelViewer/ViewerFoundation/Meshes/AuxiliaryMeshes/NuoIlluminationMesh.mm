//
//  NuoIlluminationMesh.m
//  ModelViewer
//
//  Created by middleware on 8/27/18.
//  Copyright © 2018 middleware. All rights reserved.
//

#import "NuoIlluminationMesh.h"



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
{
    NSString* shaderName = @"illumination_blend";
    
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
    
    [renderPass setFragmentTexture:_illumination atIndex:1];
    [renderPass setFragmentTexture:_illuminationOnVirtual atIndex:2];
    [renderPass setFragmentTexture:_directLighting atIndex:3];
    [renderPass setFragmentTexture:_directLightingWithShadow atIndex:4];
    [renderPass setFragmentTexture:_translucentCoverMap atIndex:5];
    [renderPass setFragmentBuffer:_paramBuffer offset:0 atIndex:0];
    [super drawMesh:renderPass];
    
    [renderPass popParameterState];
}


@end
