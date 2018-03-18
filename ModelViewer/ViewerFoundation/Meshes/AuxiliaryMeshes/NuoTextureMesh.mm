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
    id<MTLBuffer> _textureMixBuffer;
}


- (instancetype)initWithCommandQueue:(id<MTLCommandQueue>)commandQueue
{
    self = [super initWithCommandQueue:commandQueue];
    
    if (self)
    {
        _textureMixBuffer = [commandQueue.device newBufferWithLength:sizeof(TextureMixFragment)
                                                             options:MTLResourceStorageModePrivate];
    }
    
    return self;
}


- (void)makePipelineAndSampler:(MTLPixelFormat)pixelFormat
{
    NSString* shaderName = _auxiliaryTexture ? @"fragment_texture_mix" :
                                               @"fragment_texture";
     
    [self makePipelineAndSampler:pixelFormat withFragementShader:shaderName
                   withBlendMode:kBlend_None];
}


- (void)setAuxiliaryProportion:(float)auxiliaryProportion
{
    _auxiliaryProportion = auxiliaryProportion;
    
    TextureMixFragment mixFragment;
    mixFragment.mixProportion = _auxiliaryProportion;
    
    [NuoMesh updatePrivateBuffer:_textureMixBuffer withCommandQueue:self.commandQueue
                        withData:&mixFragment withSize:sizeof(TextureMixFragment)];
}


- (void)drawMesh:(id<MTLRenderCommandEncoder>)renderPass indexBuffer:(NSInteger)index
{
    [renderPass setFragmentTexture:_modelTexture atIndex:0];
    if (_auxiliaryTexture)
    {
        [renderPass setFragmentTexture:_auxiliaryTexture atIndex:1];
        [renderPass setFragmentBuffer:_textureMixBuffer offset:0 atIndex:0];
    }
    
    [super drawMesh:renderPass indexBuffer:index];
}


@end
