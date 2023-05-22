//
//  NuoRenderTarget.m
//  ModelViewer
//
//  Created by middleware on 11/7/16.
//  Updated by Dong on 5/21/23.
//  Copyright © 2023 middleware. All rights reserved.
//

#import "NuoRenderPassTarget.h"

#import "NuoRenderPassAttachment.h"
#import "NuoCommandBuffer.h"

#import "NuoClearMesh.h"





@implementation NuoRenderPassTarget
{
    NuoRenderPassEncoder* _renderPassEncoder;
    size_t _renderPassEncoderCount;
    
    NuoClearMesh* _clearMesh;
}


- (instancetype)initWithCommandQueue:(id<MTLCommandQueue>)commandQueue
                     withPixelFormat:(MTLPixelFormat)pixelFormat
                     withSampleCount:(uint)sampleCount
{
    self = [super init];
    if (self)
    {
        _targetPixelFormat = pixelFormat;
        _renderPassEncoderCount = 0;
        _device = commandQueue.device;
        _sampleCount = sampleCount;
        
        _clearMesh = [[NuoClearMesh alloc] initWithCommandQueue:commandQueue];
        _clearMesh.sampleCount = _sampleCount;
        [_clearMesh makePipelineStateWithPixelFormat:_targetPixelFormat];
        [_clearMesh setClearColor:_clearColor];
        
        _colorAttachments = [NSMutableArray new];
        
        NuoRenderPassAttachment* colorAttachment = [NuoRenderPassAttachment new];
        colorAttachment.pixelFormat = _targetPixelFormat;
        colorAttachment.sampleCount = _sampleCount;
        colorAttachment.type = kNuoRenderPassAttachment_Color;
        colorAttachment.needResolve = YES;
        colorAttachment.needClear = YES;
        colorAttachment.needStore = YES;
        [self setColorAttachment:colorAttachment forIndex:0];
        
        _depthAttachment = [NuoRenderPassAttachment new];
        _depthAttachment.pixelFormat = MTLPixelFormatDepth32Float;
        _depthAttachment.sampleCount = _sampleCount;
        _depthAttachment.type = kNuoRenderPassAttachment_Depth;
        _depthAttachment.needClear = YES;
        _depthAttachment.manageTexture = YES;
        _depthAttachment.needStore = NO;        // by default, disable the depth map from being used afterwards (espically on ASi GPU)
        _depthAttachment.device = _device;
    }
    
    return self;
}


- (BOOL)isTextureMatchDrawableSize:(id<MTLTexture>)texture
{
    return texture.width == self.drawableSize.width &&
           texture.height == self.drawableSize.height;
}


- (void)setClearColor:(MTLClearColor)clearColor
{
    _clearColor = clearColor;
    [_clearMesh setClearColor:_clearColor];
    
    for (size_t i = 0; i < _colorAttachments.count; ++i)
    {
        NuoRenderPassAttachment* colorAttachment = _colorAttachments[i];
        colorAttachment.clearColor = _clearColor;
    }
}


- (void)setDrawableSize:(CGSize)drawableSize
{
    _drawableSize = drawableSize;
    
    [self makeTextures];
}


- (void)setSampleCount:(NSUInteger)sampleCount
{
    if (_sampleCount == sampleCount)
        return;
    
    _sampleCount = sampleCount;
    
    if (_drawableSize.width > 0 && _drawableSize.height > 0)
        [self makeTextures];
}


- (void)setStoreDepth:(BOOL)storeDepth
{
    if (_storeDepth == storeDepth)
        return;
    
    _storeDepth = storeDepth;
    
    if (_drawableSize.width > 0 && _drawableSize.height > 0)
        [self makeTextures];
}



- (void)makeTextures
{
    assert(_name);
    
    if (_clearMesh.sampleCount != _sampleCount)
    {
        [_clearMesh setSampleCount:_sampleCount];
        [_clearMesh makePipelineStateWithPixelFormat:_targetPixelFormat];
    }
    
    [self setClearColor:_clearColor];
    
    for (size_t i = 0; i < _colorAttachments.count; ++i)
    {
        NuoRenderPassAttachment* colorAttachment = _colorAttachments[i];
        colorAttachment.drawableSize = self.drawableSize;
        colorAttachment.manageTexture = self.manageTargetTexture;
        colorAttachment.sharedTexture = self.sharedTargetTexture;
        colorAttachment.needResolve = YES;
        colorAttachment.sampleCount = _sampleCount;
        colorAttachment.name = _name;
        
        [colorAttachment makeTexture];
    }
    
    // the NuoRenderPassAttachment class has both needResolve and needStore properties.
    // for a depth attachement in a NuoRenderPassTarget, the two properties are considered
    // as collectively equivelent to whether the depth map is used by another renderer.
    //
    _depthAttachment.needResolve = _storeDepth;
    _depthAttachment.needStore = _storeDepth;
    
    _depthAttachment.drawableSize = self.drawableSize;
    _depthAttachment.sampleCount = _sampleCount;
    _depthAttachment.name = _name;
    [_depthAttachment makeTexture];
}



- (NuoRenderPassEncoder*)retainRenderPassEndcoder:(NuoCommandBuffer*)commandBuffer
{
    if (_renderPassEncoder)
    {
        _renderPassEncoderCount += 1;
        return _renderPassEncoder;
    }
    
    MTLRenderPassDescriptor *passDescriptor = [self currentRenderPassDescriptor];
    _renderPassEncoder = [commandBuffer renderCommandEncoderWithDescriptor:passDescriptor];
    _renderPassEncoderCount = 1;

#if !BUILT_IN_LOAD_ACTION_CLEAR
    [self clearAction:_renderPassEncoder];
#endif
    
    return _renderPassEncoder;
}



- (void)clearAction:(NuoRenderPassEncoder*)encoder
{
    assert(_clearMesh);
    
    [_clearMesh drawMesh:encoder];
}



- (void)releaseRenderPassEndcoder
{
    assert(_renderPassEncoderCount > 0);
    
    _renderPassEncoderCount -= 1;
    if (_renderPassEncoderCount == 0)
    {
        [_renderPassEncoder endEncoding];
        _renderPassEncoder = nil;
    }
}



- (MTLRenderPassDescriptor *)currentRenderPassDescriptor
{
    MTLRenderPassDescriptor *passDescriptor = [MTLRenderPassDescriptor renderPassDescriptor];
    
    for (size_t i = 0; i < _colorAttachments.count; ++i)
    {
        NuoRenderPassAttachment* colorAttachment = _colorAttachments[i];
        if (!colorAttachment.texture)
            return nil;
        
        MTLRenderPassAttachmentDescriptor* descriptor = [colorAttachment descriptor];
        passDescriptor.colorAttachments[i] = (MTLRenderPassColorAttachmentDescriptor*)descriptor;
    }
    
    MTLRenderPassAttachmentDescriptor* descriptor = [_depthAttachment descriptor];
    passDescriptor.depthAttachment = (MTLRenderPassDepthAttachmentDescriptor*)descriptor;
    
    return passDescriptor;
}



- (void)setColorAttachment:(NuoRenderPassAttachment*)colorAttachment forIndex:(NSUInteger)index
{
    NSMutableArray* attachments = (NSMutableArray*)_colorAttachments;
    colorAttachment.device = _device;
    
    if (attachments.count >= index)
    {
        attachments[index] = colorAttachment;
    }
    else
    {
        for (size_t i = attachments.count; i < index; ++i)
            [attachments insertObject:[MTLRenderPassAttachmentDescriptor new] atIndex:i];
        [attachments insertObject:colorAttachment atIndex:index];
    }
}



- (id<MTLTexture>)targetTexture
{
    NuoRenderPassAttachment* colorAttachment = _colorAttachments[0];
    return colorAttachment.texture;
}


- (id<MTLTexture>)depthTexture
{
    return _depthAttachment.texture;
}




@end
