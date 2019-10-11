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



- (void)makePipelineAndSampler:(MTLPixelFormat)pixelFormat
                 withBlendMode:(ScreenSpaceBlendMode)blendMode
                    withHybrid:(BOOL)hybrid
{
    NSString* shaderName = hybrid? @"illumination_blend_hybrid" : @"illumination_blend";
    
    [self makePipelineAndSampler:pixelFormat withFragementShader:shaderName
                   withBlendMode:blendMode];
}



- (void)drawMesh:(NuoRenderPassEncoder*)renderPass
{
    [renderPass pushParameterState:@"Illumination"];
    
    uint i = 1;
    
    [self setModelTexture:_illuminations.regularLighting];
    [renderPass setFragmentTexture:_illuminations.ambientNormal atIndex:i];
    [renderPass setFragmentTexture:_illuminations.ambientVirtual atIndex:++i];
    [renderPass setFragmentTexture:_illuminations.ambientVirtualWithoutBlock atIndex:++i];
    [renderPass setFragmentTexture:_illuminations.directVirtual atIndex:++i];
    [renderPass setFragmentTexture:_illuminations.directVirtualBlocked atIndex:++i];
    
    if (_translucentCoverMap)
        [renderPass setFragmentTexture:_translucentCoverMap atIndex:++i];
    
    [super drawMesh:renderPass];
    
    [renderPass popParameterState];
}


@end
