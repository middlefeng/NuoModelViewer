//
//  NuoShadowMapTarget.m
//  ModelViewer
//
//  Created by middleware on 1/16/17.
//  Copyright © 2017 middleware. All rights reserved.
//

#import "NuoShadowMapTarget.h"



@interface NuoShadowMapTarget()

@property (nonatomic, strong) id<MTLTexture> depthSampleTexture1;
@property (nonatomic, strong) id<MTLTexture> depthSampleTexture2;

@end




@implementation NuoShadowMapTarget



- (void)makeTextures
{
    if ([_depthSampleTexture1 width] != [self drawableSize].width ||
        [_depthSampleTexture1 height] != [self drawableSize].height)
    {
        if (self.sampleCount > 1)
        {
            MTLTextureDescriptor *sampleDesc = [MTLTextureDescriptor texture2DDescriptorWithPixelFormat:MTLPixelFormatDepth32Float
                                                                                            width:[self drawableSize].width
                                                                                           height:[self drawableSize].height
                                                                                        mipmapped:NO];
            sampleDesc.sampleCount = self.sampleCount;
            sampleDesc.textureType = MTLTextureType2DMultisample;
            sampleDesc.resourceOptions = MTLResourceStorageModePrivate;
            sampleDesc.usage = MTLTextureUsageRenderTarget;
            _depthSampleTexture1 = [self.device newTextureWithDescriptor:sampleDesc];
            
            sampleDesc.pixelFormat = MTLPixelFormatR32Float;
            _depthSampleTexture2 = [self.device newTextureWithDescriptor:sampleDesc];
            
            if (self.name)
            {
                NSString* label1 = [[NSString alloc] initWithFormat:@"%@ - %@", self.name, @"depth sample 1"];
                NSString* label2 = [[NSString alloc] initWithFormat:@"%@ - %@", self.name, @"depth sample 2"];
                [_depthSampleTexture1 setLabel:label1];
                [_depthSampleTexture2 setLabel:label2];
            }
        }
        
        MTLTextureDescriptor *desc = [MTLTextureDescriptor texture2DDescriptorWithPixelFormat:MTLPixelFormatDepth32Float
                                                                                              width:[self drawableSize].width
                                                                                             height:[self drawableSize].height
                                                                                          mipmapped:NO];
        
        desc.sampleCount = 1;
        desc.textureType = MTLTextureType2D;
        desc.resourceOptions = MTLResourceStorageModePrivate;
        desc.usage = MTLTextureUsageRenderTarget | MTLTextureUsageShaderRead;
        _shadowMap1 = [self.device newTextureWithDescriptor:desc];
        
        desc.pixelFormat = MTLPixelFormatR32Float;
        _shadowMap2 = [self.device newTextureWithDescriptor:desc];
        
        if (self.name)
        {
            NSString* label = [[NSString alloc] initWithFormat:@"%@ - %@", self.name, @"depth target 1"];
            [_shadowMap1 setLabel:label];
        }
    }
}



- (MTLRenderPassDescriptor *)currentRenderPassDescriptor
{
    MTLRenderPassDescriptor *passDescriptor = [MTLRenderPassDescriptor renderPassDescriptor];
    
    if (!_shadowMap1)
        return nil;
    
    passDescriptor.depthAttachment.texture = (self.sampleCount == 1) ? _shadowMap1 : _depthSampleTexture1;
    passDescriptor.depthAttachment.clearDepth = 1.0;
    passDescriptor.depthAttachment.loadAction = MTLLoadActionClear;
    passDescriptor.depthAttachment.storeAction = (self.sampleCount == 1) ? MTLStoreActionStore : MTLStoreActionMultisampleResolve;
    if (self.sampleCount > 1)
        passDescriptor.depthAttachment.resolveTexture = _shadowMap1;
    
    return passDescriptor;
}



- (id<MTLTexture>)targetTexture
{
    // not use the default target texture
    assert(false);
    return nil;
}





@end
