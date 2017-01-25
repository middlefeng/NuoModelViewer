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



- (void)makeTextures
{
    if ([_depthSampleTexture width] != [self drawableSize].width ||
        [_depthSampleTexture height] != [self drawableSize].height)
    {
        if (self.sampleCount > 1)
        {
            MTLTextureDescriptor *sampleDesc = [MTLTextureDescriptor texture2DDescriptorWithPixelFormat:MTLPixelFormatDepth32Float
                                                                                            width:[self drawableSize].width
                                                                                           height:[self drawableSize].height
                                                                                        mipmapped:NO];
            sampleDesc.sampleCount = self.sampleCount;
            sampleDesc.textureType = (self.sampleCount == 1) ? MTLTextureType2D : MTLTextureType2DMultisample;
            sampleDesc.resourceOptions = MTLResourceStorageModePrivate;
            sampleDesc.usage = MTLTextureUsageRenderTarget;
            
            _depthSampleTexture = [self.device newTextureWithDescriptor:sampleDesc];
            
            if (self.name)
            {
                NSString* label = [[NSString alloc] initWithFormat:@"%@ - %@", self.name, @"depth sample"];
                [_depthSampleTexture setLabel:label];
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
            
        self.targetTexture = [self.device newTextureWithDescriptor:desc];
        
        if (self.name)
        {
            NSString* label = [[NSString alloc] initWithFormat:@"%@ - %@", self.name, @"depth target"];
            [self.targetTexture setLabel:label];
        }
    }
}



- (MTLRenderPassDescriptor *)currentRenderPassDescriptor
{
    MTLRenderPassDescriptor *passDescriptor = [MTLRenderPassDescriptor renderPassDescriptor];
    
    if (!self.targetTexture)
        return nil;
    
    passDescriptor.depthAttachment.texture = (self.sampleCount == 1) ? self.targetTexture : _depthSampleTexture;
    passDescriptor.depthAttachment.clearDepth = 1.0;
    passDescriptor.depthAttachment.loadAction = MTLLoadActionClear;
    passDescriptor.depthAttachment.storeAction = (self.sampleCount == 1) ? MTLStoreActionStore : MTLStoreActionMultisampleResolve;
    if (self.sampleCount > 1)
        passDescriptor.depthAttachment.resolveTexture = self.targetTexture;
    
    return passDescriptor;
}





@end
