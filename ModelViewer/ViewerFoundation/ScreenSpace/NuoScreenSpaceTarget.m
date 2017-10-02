//
//  NuoScreenSpaceTarget.m
//  ModelViewer
//
//  Created by Dong on 9/28/17.
//  Copyright © 2017 middleware. All rights reserved.
//

#import "NuoScreenSpaceTarget.h"




@implementation NuoScreenSpaceTarget
{
    id<MTLTexture> _positionBufferSample;
    id<MTLTexture> _normalBufferSample;
    id<MTLTexture> _ambientBufferSample;
}




- (instancetype)initWithSampleCount:(unsigned int)sampleCount
{
    self = [super init];
    if (self)
    {
        self.sampleCount = sampleCount;
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
    
    if (self.sampleCount > 1)
    {
        texDesc.sampleCount = self.sampleCount;
        texDesc.textureType = MTLTextureType2DMultisample;
        
        if ([_normalBufferSample width] != [self drawableSize].width ||
            [_normalBufferSample height] != [self drawableSize].height)
        {
            _normalBufferSample = [self.device newTextureWithDescriptor:texDesc];
        }
        
        if ([_positionBufferSample width] != [self drawableSize].width ||
            [_positionBufferSample height] != [self drawableSize].height)
        {
            _positionBufferSample = [self.device newTextureWithDescriptor:texDesc];
        }
        
        if ([_ambientBufferSample width] != [self drawableSize].width ||
            [_ambientBufferSample height] != [self drawableSize].height)
        {
            _ambientBufferSample = [self.device newTextureWithDescriptor:texDesc];
        }
    }
    
    [super makeTextures];
}


- (MTLRenderPassDescriptor *)currentRenderPassDescriptor
{
    MTLRenderPassDescriptor *passDescriptor = [MTLRenderPassDescriptor renderPassDescriptor];
    MTLStoreAction storeAction = (self.sampleCount == 1) ? MTLStoreActionStore : MTLStoreActionMultisampleResolve;
    
    passDescriptor.colorAttachments[0].texture = (self.sampleCount == 1) ? _positionBuffer : _positionBufferSample;
    passDescriptor.colorAttachments[0].clearColor = self.clearColor;
    passDescriptor.colorAttachments[0].loadAction = MTLLoadActionClear;
    passDescriptor.colorAttachments[0].storeAction = storeAction;
    
    passDescriptor.colorAttachments[1].texture = (self.sampleCount == 1) ? _normalBuffer : _normalBufferSample;
    passDescriptor.colorAttachments[1].clearColor = self.clearColor;
    passDescriptor.colorAttachments[1].loadAction = MTLLoadActionClear;
    passDescriptor.colorAttachments[1].storeAction = storeAction;
    
    passDescriptor.colorAttachments[2].texture = (self.sampleCount == 1) ? _ambientBuffer : _ambientBufferSample;
    passDescriptor.colorAttachments[2].clearColor = self.clearColor;
    passDescriptor.colorAttachments[2].loadAction = MTLLoadActionClear;
    passDescriptor.colorAttachments[2].storeAction = storeAction;
    
    if (self.sampleCount > 1)
    {
        passDescriptor.colorAttachments[0].resolveTexture = _positionBuffer;
        passDescriptor.colorAttachments[1].resolveTexture = _normalBuffer;
        passDescriptor.colorAttachments[2].resolveTexture = _ambientBuffer;
    }
    
    passDescriptor.depthAttachment.texture = self.depthTexture;
    passDescriptor.depthAttachment.clearDepth = 1.0;
    passDescriptor.depthAttachment.loadAction = MTLLoadActionClear;
    passDescriptor.depthAttachment.storeAction = MTLStoreActionDontCare;
    
    return passDescriptor;
}



@end
