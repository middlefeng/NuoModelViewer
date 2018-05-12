//
//  NuoRenderTarget.m
//  ModelViewer
//
//  Created by middleware on 11/7/16.
//  Copyright © 2016 middleware. All rights reserved.
//

#import "NuoRenderPassTarget.h"
#import "NuoClearMesh.h"



@interface NuoRenderPassTarget()

@property (nonatomic, strong) id<MTLTexture> sampleTexture;
@property (nonatomic, strong) id<MTLTexture> sampleDepth;

@end




@implementation NuoRenderPassTarget
{
    id<MTLRenderCommandEncoder> _renderPassEncoder;
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


- (void)setResolveDepth:(BOOL)resolveDepth
{
    if (_resolveDepth == resolveDepth)
        return;
    
    _resolveDepth = resolveDepth;
    
    if (_drawableSize.width > 0 && _drawableSize.height > 0)
        [self makeTextures];
}



- (id<MTLTexture>)depthAttachmentTexture
{
    return (_sampleCount == 1) ? _depthTexture : _sampleDepth;
}



- (void)makeTextures
{
    assert(_name);
    
    if (_clearMesh.sampleCount != _sampleCount)
    {
        [_clearMesh setSampleCount:_sampleCount];
        [_clearMesh makePipelineStateWithPixelFormat:_targetPixelFormat];
    }
    
    if (![self isTextureMatchDrawableSize:_depthTexture] ||
        (_sampleCount > 1 && _resolveDepth && _depthTexture.sampleCount != _sampleCount))
    {
        if (_resolveDepth || _sampleCount == 1)
        {
            MTLTextureDescriptor *desc = [MTLTextureDescriptor texture2DDescriptorWithPixelFormat:MTLPixelFormatDepth32Float
                                                                                            width:[self drawableSize].width
                                                                                           height:[self drawableSize].height
                                                                                        mipmapped:NO];
            
            
            
            desc.sampleCount = 1;
            desc.textureType = MTLTextureType2D;
            desc.resourceOptions = MTLResourceStorageModePrivate;
            desc.usage = MTLTextureUsageRenderTarget | MTLTextureUsageShaderRead;
            
            self.depthTexture = [_device newTextureWithDescriptor:desc];
            
            NSString* name = [[NSString alloc] initWithFormat:@"%@ - %@", _name, @"depth"];
            [self.depthTexture setLabel:name];
        }
        
        if (_manageTargetTexture)
        {
            MTLTextureDescriptor *desc = [MTLTextureDescriptor texture2DDescriptorWithPixelFormat:_targetPixelFormat
                                                                                            width:[self drawableSize].width
                                                                                           height:[self drawableSize].height
                                                                                        mipmapped:NO];
            desc.sampleCount = 1;
            desc.textureType = MTLTextureType2D;
            desc.resourceOptions = _sharedTargetTexture ? MTLResourceStorageModeManaged : MTLResourceStorageModePrivate;
            desc.usage = MTLTextureUsageRenderTarget | MTLTextureUsageShaderRead;
            
            _targetTexture = [_device newTextureWithDescriptor:desc];
            
            NSString* name = [[NSString alloc] initWithFormat:@"%@ - %@", _name, @"target"];
            [_targetTexture setLabel:name];
        }
    }
    
    if (_sampleCount > 1 && (![self isTextureMatchDrawableSize:_sampleTexture] ||
                             _sampleTexture.sampleCount != _sampleCount))
        
    {
        MTLTextureDescriptor *sampleDesc = [MTLTextureDescriptor texture2DDescriptorWithPixelFormat:_targetPixelFormat
                                                                                              width:[self drawableSize].width
                                                                                             height:[self drawableSize].height
                                                                                          mipmapped:NO];
        
        sampleDesc.sampleCount = _sampleCount;
        sampleDesc.textureType = MTLTextureType2DMultisample;
        sampleDesc.resourceOptions = MTLResourceStorageModePrivate;
        sampleDesc.usage = MTLTextureUsageRenderTarget;
        
        self.sampleTexture = [_device newTextureWithDescriptor:sampleDesc];
        
        NSString* sampleName = [[NSString alloc] initWithFormat:@"%@ - %@", _name, @"sample"];
        [self.sampleTexture setLabel:sampleName];
        
        sampleDesc.textureType = MTLTextureType2DMultisample;
        sampleDesc.pixelFormat = MTLPixelFormatDepth32Float;
        
        self.sampleDepth = [_device newTextureWithDescriptor:sampleDesc];
        NSString* sampleDepthName = [[NSString alloc] initWithFormat:@"%@ - %@", _name, @"depth sample"];
        [self.sampleDepth setLabel:sampleDepthName];
    }
}



- (id<MTLRenderCommandEncoder>)retainRenderPassEndcoder:(id<MTLCommandBuffer>)commandBuffer;
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



- (void)clearAction:(id<MTLRenderCommandEncoder>)encoder
{
    assert(_clearMesh);
    
    [_clearMesh drawMesh:encoder indexBuffer:0];
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
    
    if (!_targetTexture)
        return nil;
    
    passDescriptor.colorAttachments[0].texture = (_sampleCount == 1) ? _targetTexture : _sampleTexture;
    passDescriptor.colorAttachments[0].clearColor = _clearColor;
    passDescriptor.colorAttachments[0].loadAction = NUO_LOAD_ACTION;
    passDescriptor.colorAttachments[0].storeAction = (_sampleCount == 1) ? MTLStoreActionStore : MTLStoreActionMultisampleResolve;
    if (_sampleCount > 1)
        passDescriptor.colorAttachments[0].resolveTexture = _targetTexture;
    
    passDescriptor.depthAttachment.texture = (_sampleCount == 1) ? self.depthTexture : self.sampleDepth;
    passDescriptor.depthAttachment.clearDepth = 1.0;
    passDescriptor.depthAttachment.loadAction = MTLLoadActionClear;
    
    if (_resolveDepth)
    {
        if (_sampleCount > 1)
        {
            passDescriptor.depthAttachment.resolveTexture = self.depthTexture;
            passDescriptor.depthAttachment.storeAction = MTLStoreActionMultisampleResolve;
        }
        else
        {
            passDescriptor.depthAttachment.storeAction = MTLStoreActionStore;
        }
    }
    else
    {
        passDescriptor.depthAttachment.storeAction = MTLStoreActionDontCare;
    }
    
    return passDescriptor;
}





@end
