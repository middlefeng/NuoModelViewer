//
//  NuoShadowMapTarget.m
//  ModelViewer
//
//  Created by middleware on 1/16/17.
//  Copyright © 2017 middleware. All rights reserved.
//

#import "NuoShadowMapTarget.h"



@interface NuoShadowMapTarget()

@property (nonatomic, strong) id<MTLTexture> depthSampleTexture;

@end




@implementation NuoShadowMapTarget


- (void)setDrawableSize:(CGSize)drawableSize
{
    _drawableSize = drawableSize;
    
    [self makeTextures];
}


- (void)makeTextures
{
    if ([_depthSampleTexture width] != [self drawableSize].width ||
        [_depthSampleTexture height] != [self drawableSize].height)
    {
        if (_sampleCount > 1)
        {
            MTLTextureDescriptor *sampleDesc = [MTLTextureDescriptor texture2DDescriptorWithPixelFormat:MTLPixelFormatDepth32Float
                                                                                            width:[self drawableSize].width
                                                                                           height:[self drawableSize].height
                                                                                        mipmapped:NO];
            sampleDesc.sampleCount = _sampleCount;
            sampleDesc.textureType = (_sampleCount == 1) ? MTLTextureType2D : MTLTextureType2DMultisample;
            sampleDesc.resourceOptions = MTLResourceStorageModePrivate;
            sampleDesc.usage = MTLTextureUsageRenderTarget;
            
            _depthSampleTexture = [_device newTextureWithDescriptor:sampleDesc];
            
            if (_name)
            {
                NSString* label = [[NSString alloc] initWithFormat:@"%@ - %@", _name, @"depth sample"];
                [_depthSampleTexture setLabel:label];
            }
        }
        
        MTLTextureDescriptor *desc = [MTLTextureDescriptor texture2DDescriptorWithPixelFormat:MTLPixelFormatBGRA8Unorm
                                                                                              width:[self drawableSize].width
                                                                                             height:[self drawableSize].height
                                                                                          mipmapped:NO];
        
        desc.sampleCount = 1;
        desc.textureType = MTLTextureType2D;
        desc.resourceOptions = MTLResourceStorageModePrivate;
        desc.usage = MTLTextureUsageRenderTarget | MTLTextureUsageShaderRead;
            
        _targetTexture = [_device newTextureWithDescriptor:desc];
        
        if (_name)
        {
            NSString* label = [[NSString alloc] initWithFormat:@"%@ - %@", _name, @"depth target"];
            [_targetTexture setLabel:label];
        }
    }
}



- (MTLRenderPassDescriptor *)currentRenderPassDescriptor
{
    MTLRenderPassDescriptor *passDescriptor = [MTLRenderPassDescriptor renderPassDescriptor];
    
    if (!_targetTexture)
        return nil;
    
    passDescriptor.depthAttachment.texture = (_sampleCount == 1) ? _targetTexture : _depthSampleTexture;
    passDescriptor.depthAttachment.clearDepth = 1.0;
    passDescriptor.depthAttachment.loadAction = MTLLoadActionClear;
    passDescriptor.depthAttachment.storeAction = (_sampleCount == 1) ? MTLStoreActionStore : MTLStoreActionMultisampleResolve;
    if (_sampleCount > 1)
        passDescriptor.depthAttachment.resolveTexture = _targetTexture;
    
    return passDescriptor;
}





@end
