//
//  NuoTextureMesh.m
//  ModelViewer
//
//  Created by middleware on 11/3/16.
//  Copyright © 2017 middleware. All rights reserved.
//

#import "NuoTextureMesh.h"
#import "NuoTextureBase.h"

struct TextureMixFragment
{
    float mixProportion;
};


@implementation NuoTextureMesh
{
    NSArray<id<MTLBuffer>>* _textureMixBuffer;
}


- (instancetype)initWithDevice:(id<MTLDevice>)device
{
    self = [super initWithDevice:device];
    
    if (self)
    {
        id<MTLBuffer> buffers[kInFlightBufferCount];
        for (size_t i = 0; i < kInFlightBufferCount; ++i)
            buffers[i] = [device newBufferWithLength:sizeof(TextureMixFragment)
                                            options:MTLResourceOptionCPUCacheModeDefault];
        _textureMixBuffer = [[NSArray alloc] initWithObjects:buffers count:kInFlightBufferCount];
    }
    
    return self;
}


- (void)makePipelineAndSampler:(MTLPixelFormat)pixelFormat withSampleCount:(NSUInteger)sampleCount
{
    NSString* shaderName = _auxiliaryTexture ? @"fragment_texutre_mix" :
                                               @"fragment_texutre";
     
    [self makePipelineAndSampler:pixelFormat withFragementShader:shaderName
                 withSampleCount:sampleCount withAlpha:NO];
}


- (void)updateUniform:(NSInteger)bufferIndex withTransform:(matrix_float4x4)transform
{
    [super updateUniform:bufferIndex withTransform:transform];
    
    if (_auxiliaryTexture)
    {
        TextureMixFragment mixFragment;
        mixFragment.mixProportion = _auxiliaryProportion;
        memcpy(_textureMixBuffer[bufferIndex].contents, &mixFragment, sizeof(TextureMixFragment));
    }
}


- (void)drawMesh:(id<MTLRenderCommandEncoder>)renderPass indexBuffer:(NSInteger)index
{
    [self updateUniform:index withTransform:matrix_identity_float4x4];
    
    [renderPass setFragmentTexture:_modelTexture atIndex:0];
    if (_auxiliaryTexture)
    {
        [renderPass setFragmentTexture:_auxiliaryTexture atIndex:1];
        [renderPass setFragmentBuffer:_textureMixBuffer[index] offset:0 atIndex:0];
    }
    
    [super drawMesh:renderPass indexBuffer:index];
}


@end
