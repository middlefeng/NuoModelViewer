//
//  NuoTextureAverageMesh.m
//  ModelViewer
//
//  Created by Dong on 11/11/17.
//  Copyright © 2017 middleware. All rights reserved.
//

#import "NuoTextureAverageMesh.h"

#import "NuoRenderPassTarget.h"
#import "NuoTextureMesh.h"




@implementation NuoTextureAverageMesh
{
    // mesh used to duplicate texture
    NuoTextureMesh* _accumulatedMesh;
    
    NuoRenderPassTarget* _texturesAccumulated;
    id<MTLTexture> _textureLatest;
    NSUInteger _textureCount;
    
    NSArray<id<MTLBuffer>>* _texCountBuffer;
}


- (instancetype)initWithCommandQueue:(id<MTLCommandQueue>)commandQueue
{
    self = [super initWithCommandQueue:commandQueue];
    
    if (self)
    {
        id<MTLBuffer> buffers[kInFlightBufferCount];
        for (size_t i = 0; i < kInFlightBufferCount; ++i)
            buffers[i] = [commandQueue.device newBufferWithLength:sizeof(int)
                                                          options:MTLResourceStorageModeManaged];
        _texCountBuffer = [[NSArray alloc] initWithObjects:buffers count:kInFlightBufferCount];
        
        _textureCount = 0;
    }
    
    return self;
}


- (void)makePipelineAndSampler
{
    NSString* shaderName = @"fragment_texutre_average";
    
    _texturesAccumulated = [NuoRenderPassTarget new];
    _texturesAccumulated.device = self.device;
    _texturesAccumulated.sampleCount = 1;
    _texturesAccumulated.clearColor = MTLClearColorMake(0, 0, 0, 0);
    _texturesAccumulated.manageTargetTexture = YES;
    _texturesAccumulated.name = @"Average Texture";
    
    _accumulatedMesh = [[NuoTextureMesh alloc] initWithCommandQueue:self.commandQueue];
    [_accumulatedMesh makePipelineAndSampler:MTLPixelFormatBGRA8Unorm withSampleCount:1];
    
    [self makePipelineAndSampler:MTLPixelFormatBGRA8Unorm withFragementShader:shaderName
                 withSampleCount:1 withBlendMode:kBlend_Accumulate];
}



- (void)appendTexture:(id<MTLTexture>)texture
{
    _textureLatest = texture;
    _textureCount += 1;
}



- (void)accumulateTexture:(id<MTLTexture>)texture
                 onTarget:(NuoRenderPassTarget*)target
             withInFlight:(NSUInteger)inFlight
        withCommandBuffer:(id<MTLCommandBuffer>)commandBuffer
{
    [self appendTexture:texture];
    
    // accumulate the texture onto the target
    
    id<MTLRenderCommandEncoder> renderPass = [target retainRenderPassEndcoder:commandBuffer];
    renderPass.label = @"Motion Blur Pass";
    
    [self drawMesh:renderPass indexBuffer:inFlight];
    [target releaseRenderPassEndcoder];
    
    // copy pixels from the render target to the accumulation texture
    
    [self setAccumulateTexture:target.targetTexture withCommandBuffer:commandBuffer];
}


- (void)setAccumulateTexture:(id<MTLTexture>)texture withCommandBuffer:(id<MTLCommandBuffer>)commandBuffer
{
    [_texturesAccumulated setDrawableSize:CGSizeMake(texture.width, texture.height)];
    
    id<MTLRenderCommandEncoder> accumulatePass = [_texturesAccumulated retainRenderPassEndcoder:commandBuffer];
    [_accumulatedMesh setModelTexture:texture];
    [_accumulatedMesh drawMesh:accumulatePass indexBuffer:0];
    [_texturesAccumulated releaseRenderPassEndcoder];
    
    /**
     *  BLIT copy can NOT handle framebuffer-only source texture, nor can it handle texture size change.
     *
     *  the code above change _texturesAccumulated to a render-target, which resolves the texture creation,
     *  and texture copy by rendering
     *
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
    
    [encoder endEncoding];*/
}



- (void)updateUniform:(NSInteger)bufferIndex withTransform:(matrix_float4x4)transform
{
    memcpy(_texCountBuffer[bufferIndex].contents, &_textureCount, sizeof(int));
    [_texCountBuffer[bufferIndex] didModifyRange:NSMakeRange(0, sizeof(int))];
}



- (void)drawMesh:(id<MTLRenderCommandEncoder>)renderPass indexBuffer:(NSInteger)index
{
    [self updateUniform:index withTransform:matrix_identity_float4x4];
    
    [renderPass setFragmentTexture:_texturesAccumulated.targetTexture atIndex:0];
    [renderPass setFragmentTexture:_textureLatest atIndex:1];
    [renderPass setFragmentBuffer:_texCountBuffer[index] offset:0 atIndex:0];
    [super drawMesh:renderPass indexBuffer:index];
}



@end
