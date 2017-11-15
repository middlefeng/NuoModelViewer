//
//  NuoTextureAverageMesh.m
//  ModelViewer
//
//  Created by Dong on 11/11/17.
//  Copyright © 2017 middleware. All rights reserved.
//

#import "NuoTextureAverageMesh.h"



@implementation NuoTextureAverageMesh
{
    id<MTLTexture> _texturesAccumulated;
    id<MTLTexture> _textureLatest;
    NSUInteger _textureCount;
    
    NSArray<id<MTLBuffer>>* _texCountBuffer;
}


- (instancetype)initWithDevice:(id<MTLDevice>)device
{
    self = [super initWithDevice:device];
    
    if (self)
    {
        id<MTLBuffer> buffers[kInFlightBufferCount];
        for (size_t i = 0; i < kInFlightBufferCount; ++i)
            buffers[i] = [device newBufferWithLength:sizeof(int)
                                             options:MTLResourceStorageModeManaged];
        _texCountBuffer = [[NSArray alloc] initWithObjects:buffers count:kInFlightBufferCount];
        
        _textureCount = 0;
    }
    
    return self;
}


- (void)makePipelineAndSampler
{
    NSString* shaderName = @"fragment_texutre_average";
    
    [self makePipelineAndSampler:MTLPixelFormatBGRA8Unorm withFragementShader:shaderName
                 withSampleCount:1 withBlendMode:kBlend_Accumulate];
}



- (void)appendTexture:(id<MTLTexture>)texture
{
    _textureLatest = texture;
    _textureCount += 1;
}


- (void)accumulateTexture:(id<MTLTexture>)texture withCommandBuffer:(id<MTLCommandBuffer>)commandBuffer
{
    if (!_texturesAccumulated)
    {
        MTLTextureDescriptor *desc = [MTLTextureDescriptor texture2DDescriptorWithPixelFormat:MTLPixelFormatBGRA8Unorm
                                                                                        width:texture.width
                                                                                       height:texture.height
                                                                                    mipmapped:NO];
        desc.sampleCount = 1;
        desc.textureType = MTLTextureType2D;
        desc.resourceOptions = MTLResourceStorageModePrivate;
        desc.usage = MTLTextureUsageRenderTarget | MTLTextureUsageShaderRead;
        
        _texturesAccumulated = [self.device newTextureWithDescriptor:desc];
    }
    
    MTLOrigin origin = {0, 0, 0};
    MTLSize size = {texture.width, texture.height, 1};
    id<MTLBlitCommandEncoder> encoder = [commandBuffer blitCommandEncoder];
    [encoder copyFromTexture:texture sourceSlice:0 sourceLevel:0 sourceOrigin:origin sourceSize:size
                   toTexture:_texturesAccumulated destinationSlice:0 destinationLevel:0 destinationOrigin:origin];
    
    [encoder endEncoding];
}



- (void)updateUniform:(NSInteger)bufferIndex withTransform:(matrix_float4x4)transform
{
    memcpy(_texCountBuffer[bufferIndex].contents, &_textureCount, sizeof(int));
    [_texCountBuffer[bufferIndex] didModifyRange:NSMakeRange(0, sizeof(int))];
}



- (void)drawMesh:(id<MTLRenderCommandEncoder>)renderPass indexBuffer:(NSInteger)index
{
    [self updateUniform:index withTransform:matrix_identity_float4x4];
    
    [renderPass setFragmentTexture:_texturesAccumulated atIndex:0];
    [renderPass setFragmentTexture:_textureLatest atIndex:1];
    [renderPass setFragmentBuffer:_texCountBuffer[index] offset:0 atIndex:0];
    [super drawMesh:renderPass indexBuffer:index];
}



@end
