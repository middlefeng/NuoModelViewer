//
//  NuoRenderPassAttachment.m
//  ModelViewer
//
//  Created by Dong on 5/25/18.
//  Copyright © 2018 middleware. All rights reserved.
//

#import "NuoRenderPassAttachment.h"
#import "NuoRenderPassTarget.h"



@implementation NuoRenderPassAttachment
{
    id<MTLTexture> _sampleTexture;
}


- (void)makeTexture
{
    BOOL drawableSizeChanged = false;
    if (_texture.width != _drawableSize.width || _texture.height != _drawableSize.height)
        drawableSizeChanged = true;
    
    BOOL sampleCountChanged = false;
    if (_sampleCount > 1 && !_sampleTexture)
        sampleCountChanged = true;
    if (_sampleCount != _sampleTexture.sampleCount)
        sampleCountChanged = true;
    if (_sampleCount == 1 && !(_sampleTexture) && _texture.sampleCount == 1)
        sampleCountChanged = false;
    
    if (!drawableSizeChanged && !sampleCountChanged)
        return;
        
        
    if (_manageTexture && (_needResolve || _sampleCount == 1))
    {
        MTLTextureDescriptor *desc = [MTLTextureDescriptor texture2DDescriptorWithPixelFormat:_pixelFormat
                                                                                        width:_drawableSize.width
                                                                                       height:_drawableSize.height
                                                                                    mipmapped:NO];
        
        
        
        desc.sampleCount = 1;
        desc.textureType = MTLTextureType2D;
        desc.resourceOptions = _sharedTexture ? MTLResourceStorageModeManaged : MTLResourceStorageModePrivate;
        desc.usage = MTLTextureUsageRenderTarget | MTLTextureUsageShaderRead;
        if (_needWrite)
            desc.usage |= MTLTextureUsageShaderWrite;
        
        _texture = [_device newTextureWithDescriptor:desc];
        [_texture setLabel:_name];
    }
    
    if (_sampleCount > 1)
    {
        MTLTextureDescriptor *sampleDesc = [MTLTextureDescriptor texture2DDescriptorWithPixelFormat:_pixelFormat
                                                                                              width:_drawableSize.width
                                                                                             height:_drawableSize.height
                                                                                          mipmapped:NO];
        
        sampleDesc.sampleCount = _sampleCount;
        sampleDesc.textureType = MTLTextureType2DMultisample;
        sampleDesc.resourceOptions = MTLResourceStorageModePrivate;
        sampleDesc.usage = MTLTextureUsageRenderTarget;
        
        _sampleTexture = [_device newTextureWithDescriptor:sampleDesc];
        
        NSString* name = [NSString stringWithFormat:@"%@ Sample", _name];
        [_sampleTexture setLabel:name];
    }
}


- (MTLRenderPassAttachmentDescriptor*)descriptor
{
    MTLRenderPassAttachmentDescriptor* result = nil;
    
    if (_type == kNuoRenderPassAttachment_Color)
    {
        result = [MTLRenderPassColorAttachmentDescriptor new];
        ((MTLRenderPassColorAttachmentDescriptor*)result).clearColor = _clearColor;
        result.loadAction = _needClear ? NUO_LOAD_ACTION : MTLLoadActionDontCare;
    }
    
    if (_type == kNuoRenderPassAttachment_Depth)
    {
        result = [MTLRenderPassDepthAttachmentDescriptor new];
        ((MTLRenderPassDepthAttachmentDescriptor*)result).clearDepth = 1.0;
        
        // there is no code to clear the depth buffer without the built-in render pass
        // clear action support, so MTLLoadActionClear is aleays used
        //
        result.loadAction = MTLLoadActionClear;
    }
        
    result.texture = (_sampleCount == 1) ? _texture : _sampleTexture;
    result.storeAction = MTLStoreActionDontCare;

    if (_needStore || _needResolve)
    {
        if (_sampleCount > 1 && _needResolve)
        {
            result.storeAction = _needStore ? MTLStoreActionStoreAndMultisampleResolve : MTLStoreActionMultisampleResolve;
            result.resolveTexture = _texture;
        }
        else if (_needStore)
        {
            result.storeAction = MTLStoreActionStore;
        }
    }

    return result;
}


@end
