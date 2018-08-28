//
//  NuoIlluminationMesh.m
//  ModelViewer
//
//  Created by middleware on 8/27/18.
//  Copyright © 2018 middleware. All rights reserved.
//

#import "NuoIlluminationMesh.h"



@implementation NuoIlluminationMesh


- (void)makePipelineAndSampler:(MTLPixelFormat)pixelFormat
                 withBlendMode:(ScreenSpaceBlendMode)blendMode
{
    NSString* shaderName = @"illumination_blend";
    
    [self makePipelineAndSampler:pixelFormat withFragementShader:shaderName
                   withBlendMode:blendMode];
}



- (void)drawMesh:(id<MTLRenderCommandEncoder>)renderPass indexBuffer:(NSInteger)index
{
    [renderPass setFragmentTexture:_illuminationMap atIndex:1];
    [super drawMesh:renderPass indexBuffer:index];
}


@end
