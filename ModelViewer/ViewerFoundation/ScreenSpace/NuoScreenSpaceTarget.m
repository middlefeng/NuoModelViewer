//
//  NuoScreenSpaceTarget.m
//  ModelViewer
//
//  Created by Dong on 9/28/17.
//  Copyright © 2017 middleware. All rights reserved.
//

#import "NuoScreenSpaceTarget.h"




@implementation NuoScreenSpaceTarget



- (instancetype)init
{
    self = [super init];
    if (self)
    {
        self.sampleCount = 1;
        self.manageTargetTexture = NO;  // not use the default color target
        self.clearColor = MTLClearColorMake(0.0, 0.0, 0.0, 0.0);
    }
    return self;
}


- (void)makeTextures
{
    MTLTextureDescriptor *texDesc = [MTLTextureDescriptor texture2DDescriptorWithPixelFormat:MTLPixelFormatRGBA16Float
                                                                                       width:[self drawableSize].width
                                                                                      height:[self drawableSize].height
                                                                                   mipmapped:NO];
    texDesc.sampleCount = 1;
    texDesc.textureType = MTLTextureType2D;
    texDesc.resourceOptions = MTLResourceStorageModePrivate;
    texDesc.usage = MTLTextureUsageRenderTarget | MTLTextureUsageShaderRead;
    
    if ([_normalBuffer width] != [self drawableSize].width ||
        [_normalBuffer height] != [self drawableSize].height)
    {
        _normalBuffer = [self.device newTextureWithDescriptor:texDesc];
    }
    
    if ([_positionBuffer width] != [self drawableSize].width ||
        [_positionBuffer height] != [self drawableSize].height)
    {
        _positionBuffer = [self.device newTextureWithDescriptor:texDesc];
    }
    
    if ([_ambientBuffer width] != [self drawableSize].width ||
        [_ambientBuffer height] != [self drawableSize].height)
    {
        _ambientBuffer = [self.device newTextureWithDescriptor:texDesc];
    }
    
    [super makeTextures];
}


- (MTLRenderPassDescriptor *)currentRenderPassDescriptor
{
    MTLRenderPassDescriptor *passDescriptor = [MTLRenderPassDescriptor renderPassDescriptor];
    
    passDescriptor.colorAttachments[0].texture = _positionBuffer;
    passDescriptor.colorAttachments[0].clearColor = self.clearColor;
    passDescriptor.colorAttachments[0].loadAction = MTLLoadActionClear;
    passDescriptor.colorAttachments[0].storeAction = MTLStoreActionStore;
    
    passDescriptor.colorAttachments[1].texture = _normalBuffer;
    passDescriptor.colorAttachments[1].clearColor = self.clearColor;
    passDescriptor.colorAttachments[1].loadAction = MTLLoadActionClear;
    passDescriptor.colorAttachments[1].storeAction = MTLStoreActionStore;
    
    passDescriptor.colorAttachments[2].texture = _ambientBuffer;
    passDescriptor.colorAttachments[2].clearColor = self.clearColor;
    passDescriptor.colorAttachments[2].loadAction = MTLLoadActionClear;
    passDescriptor.colorAttachments[2].storeAction = MTLStoreActionStore;
    
    passDescriptor.depthAttachment.texture = self.depthTexture;
    passDescriptor.depthAttachment.clearDepth = 1.0;
    passDescriptor.depthAttachment.loadAction = MTLLoadActionClear;
    passDescriptor.depthAttachment.storeAction = MTLStoreActionDontCare;
    
    return passDescriptor;
}



@end
