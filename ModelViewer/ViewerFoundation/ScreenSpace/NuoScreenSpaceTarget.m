//
//  NuoScreenSpaceTarget.m
//  ModelViewer
//
//  Created by Dong on 9/28/17.
//  Copyright © 2017 middleware. All rights reserved.
//

#import "NuoScreenSpaceTarget.h"
#import "NuoClearMesh.h"



@implementation NuoScreenSpaceTarget
{
    id<MTLTexture> _positionBufferSample;
    id<MTLTexture> _normalBufferSample;
    id<MTLTexture> _ambientBufferSample;
    id<MTLTexture> _shadowOverlayBufferSample;
    
    NuoClearMesh* _clearMesh;
}




- (instancetype)initWithCommandQueue:(id<MTLCommandQueue>)commandQueue withSampleCount:(uint)sampleCount
{
    self = [super initWithCommandQueue:commandQueue withSampleCount:sampleCount];
    if (self)
    {
        self.manageTargetTexture = NO;  // not use the default color target
        self.clearColor = MTLClearColorMake(0.0, 0.0, 0.0, 0.0);
        
        _clearMesh = [[NuoClearMesh alloc] initWithCommandQueue:commandQueue];
        [_clearMesh makePipelineScreenSpaceState];
        [_clearMesh setClearColor:self.clearColor];
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
    
    MTLTextureDescriptor *texDescR = [MTLTextureDescriptor texture2DDescriptorWithPixelFormat:MTLPixelFormatR8Unorm
                                                                                        width:[self drawableSize].width
                                                                                       height:[self drawableSize].height
                                                                                    mipmapped:NO];
    texDescR.sampleCount = 1;
    texDescR.textureType = MTLTextureType2D;
    texDescR.resourceOptions = MTLResourceStorageModePrivate;
    texDescR.usage = MTLTextureUsageRenderTarget | MTLTextureUsageShaderRead;
    if ([_shadowOverlayBuffer width] != [self drawableSize].width ||
        [_shadowOverlayBuffer height] != [self drawableSize].height)
    {
        _shadowOverlayBuffer = [self.device newTextureWithDescriptor:texDescR];
    }
    
    if (self.sampleCount > 1)
    {
        texDesc.sampleCount = self.sampleCount;
        texDesc.textureType = MTLTextureType2DMultisample;
        
        texDescR.sampleCount = self.sampleCount;
        texDescR.textureType = MTLTextureType2DMultisample;
        
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
        
        if ([_shadowOverlayBufferSample width] != [self drawableSize].width ||
            [_shadowOverlayBufferSample height] != [self drawableSize].height)
        {
            _shadowOverlayBufferSample = [self.device newTextureWithDescriptor:texDescR];
        }
    }
    
    [super makeTextures];
}


- (void)clearAction:(id<MTLRenderCommandEncoder>)encoder
{
    [_clearMesh drawScreenSpace:encoder indexBuffer:0];
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
    
    passDescriptor.colorAttachments[3].texture = (self.sampleCount == 1) ? _shadowOverlayBuffer : _shadowOverlayBufferSample;
    passDescriptor.colorAttachments[3].clearColor = self.clearColor;
    passDescriptor.colorAttachments[3].loadAction = MTLLoadActionClear;
    passDescriptor.colorAttachments[3].storeAction = storeAction;
    
    if (self.sampleCount > 1)
    {
        passDescriptor.colorAttachments[0].resolveTexture = _positionBuffer;
        passDescriptor.colorAttachments[1].resolveTexture = _normalBuffer;
        passDescriptor.colorAttachments[2].resolveTexture = _ambientBuffer;
        passDescriptor.colorAttachments[3].resolveTexture = _shadowOverlayBuffer;
    }
    
    passDescriptor.depthAttachment.texture = self.depthTexture;
    passDescriptor.depthAttachment.clearDepth = 1.0;
    passDescriptor.depthAttachment.loadAction = MTLLoadActionClear;
    passDescriptor.depthAttachment.storeAction = MTLStoreActionDontCare;
    
    return passDescriptor;
}



@end
