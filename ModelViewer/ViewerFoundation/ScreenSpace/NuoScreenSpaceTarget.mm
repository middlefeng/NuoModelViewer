//
//  NuoScreenSpaceTarget.m
//  ModelViewer
//
//  Created by Dong on 9/28/17.
//  Copyright © 2017 middleware. All rights reserved.
//

#import "NuoScreenSpaceTarget.h"
#import "NuoClearMesh.h"
#import "NuoRenderPassAttachment.h"



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
    self = [super initWithCommandQueue:commandQueue
                       withPixelFormat:MTLPixelFormatBGRA8Unorm
                       withSampleCount:sampleCount];
    if (self)
    {
        self.manageTargetTexture = YES;
        self.clearColor = MTLClearColorMake(0.0, 0.0, 0.0, 1.0);
        
        _clearMesh = [[NuoClearMesh alloc] initWithCommandQueue:commandQueue];
        [_clearMesh makePipelineScreenSpaceState];
        [_clearMesh setClearColor:self.clearColor];
        
        for (size_t i = 0; i < 3; ++i)
        {
            NuoRenderPassAttachment* colorAttachment = [NuoRenderPassAttachment new];
            colorAttachment.pixelFormat = MTLPixelFormatRGBA16Float;
            colorAttachment.type = kNuoRenderPassAttachment_Color;
            colorAttachment.needResolve = YES;
            colorAttachment.needClear = YES;
            colorAttachment.needStore = YES;
            [self setColorAttachment:colorAttachment forIndex:i];
        }
        
        NuoRenderPassAttachment* colorAttachment = [NuoRenderPassAttachment new];
        colorAttachment.pixelFormat = MTLPixelFormatR8Unorm;
        colorAttachment.type = kNuoRenderPassAttachment_Color;
        colorAttachment.needResolve = YES;
        colorAttachment.needClear = YES;
        colorAttachment.needStore = YES;
        [self setColorAttachment:colorAttachment forIndex:3];
    }
    return self;
}


- (void)makeTextures
{
    if (_clearMesh.sampleCount != self.sampleCount)
    {
        [_clearMesh setSampleCount:self.sampleCount];
        [_clearMesh makePipelineScreenSpaceState];
    }
    
    [super makeTextures];
}


- (id<MTLTexture>)positionBuffer
{
    return self.colorAttachments[0].texture;
}


- (id<MTLTexture>)normalBuffer
{
    return self.colorAttachments[1].texture;
}


- (id<MTLTexture>)ambientBuffer
{
    return self.colorAttachments[2].texture;
}


- (id<MTLTexture>)shadowOverlayBuffer
{
    return self.colorAttachments[3].texture;
}


- (void)clearAction:(id<MTLRenderCommandEncoder>)encoder
{
    [_clearMesh drawScreenSpace:encoder];
}


@end
