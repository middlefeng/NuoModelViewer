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
#import "NuoRenderPassAttachment.h"




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
    
    _texturesAccumulated = [[NuoRenderPassTarget alloc] initWithCommandQueue:self.commandQueue
                                                             withPixelFormat:MTLPixelFormatBGRA8Unorm
                                                             withSampleCount:1];
    
    _texturesAccumulated.clearColor = MTLClearColorMake(0, 0, 0, 0);
    _texturesAccumulated.manageTargetTexture = YES;
    _texturesAccumulated.name = @"Average Texture";
    
    _accumulatedMesh = [[NuoTextureMesh alloc] initWithCommandQueue:self.commandQueue];
    _accumulatedMesh.sampleCount = 1;
    [_accumulatedMesh makePipelineAndSampler:MTLPixelFormatBGRA8Unorm withBlendMode:kBlend_None];
    
    [self makePipelineAndSampler:MTLPixelFormatBGRA8Unorm withFragementShader:shaderName
                   withBlendMode:kBlend_Accumulate];
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



- (void)updateUniform:(NSInteger)bufferIndex withTransform:(const NuoMatrixFloat44&)transform
{
    memcpy(_texCountBuffer[bufferIndex].contents, &_textureCount, sizeof(int));
    [_texCountBuffer[bufferIndex] didModifyRange:NSMakeRange(0, sizeof(int))];
}



- (void)drawMesh:(id<MTLRenderCommandEncoder>)renderPass indexBuffer:(NSInteger)index
{
    [self updateUniform:index withTransform:NuoMatrixFloat44Identity];
    
    [renderPass setFragmentTexture:_texturesAccumulated.targetTexture atIndex:0];
    [renderPass setFragmentTexture:_textureLatest atIndex:1];
    [renderPass setFragmentBuffer:_texCountBuffer[index] offset:0 atIndex:0];
    [super drawMesh:renderPass indexBuffer:index];
}



@end





@implementation NuoTextureAccumulator
{
    // mesh used to duplicate texture when the target is frame buffer only
    //
    NuoTextureMesh* _accumulatedMesh;
    
    NuoRenderPassTarget* _texturesAccumulated;
    
    id<MTLCommandQueue> _commandQueue;
    id<MTLComputePipelineState> _pipelineState;
    id<MTLComputePipelineState> _pipelineStateCopy;
    
    id<MTLTexture> _textureLatest;
    uint32_t _textureCount;
    
    NSArray<id<MTLBuffer>>* _texCountBuffer;
}


- (instancetype)initWithCommandQueue:(id<MTLCommandQueue>)commandQueue
{
    self = [super init];
    
    if (self)
    {
        _commandQueue = commandQueue;
        
        id<MTLBuffer> buffers[kInFlightBufferCount];
        for (size_t i = 0; i < kInFlightBufferCount; ++i)
            buffers[i] = [commandQueue.device newBufferWithLength:sizeof(uint32_t)
                                                          options:MTLResourceStorageModeManaged];
        _texCountBuffer = [[NSArray alloc] initWithObjects:buffers count:kInFlightBufferCount];
        
        _textureCount = 0;
    }
    
    return self;
}


- (void)makePipelineAndSampler
{
    NSString* shaderName = @"compute_texutre_average";
    
    _texturesAccumulated = [[NuoRenderPassTarget alloc] initWithCommandQueue:_commandQueue
                                                             withPixelFormat:MTLPixelFormatRGBA32Float
                                                             withSampleCount:1];
    
    _texturesAccumulated.clearColor = MTLClearColorMake(0, 0, 0, 0);
    _texturesAccumulated.manageTargetTexture = YES;
    _texturesAccumulated.colorAttachments[0].needWrite = YES;
    _texturesAccumulated.name = @"Average Texture";
    
    _accumulatedMesh = [[NuoTextureMesh alloc] initWithCommandQueue:_commandQueue];
    _accumulatedMesh.sampleCount = 1;
    [_accumulatedMesh makePipelineAndSampler:MTLPixelFormatBGRA8Unorm withBlendMode:kBlend_None];
    
    id<MTLLibrary> library = [_commandQueue.device newDefaultLibrary];
    
    MTLComputePipelineDescriptor *pipelineDescriptor = [MTLComputePipelineDescriptor new];
    pipelineDescriptor.threadGroupSizeIsMultipleOfThreadExecutionWidth = YES;
    
    NSError* error = nil;
    pipelineDescriptor.computeFunction = [library newFunctionWithName:shaderName];
    _pipelineState = [_commandQueue.device newComputePipelineStateWithDescriptor:pipelineDescriptor options:0
                                                                      reflection:nil error:&error];
    
    pipelineDescriptor.computeFunction = [library newFunctionWithName:@"compute_texture_copy"];
    _pipelineStateCopy = [_commandQueue.device newComputePipelineStateWithDescriptor:pipelineDescriptor options:0
                                                                          reflection:nil error:&error];
    
    assert(error == nil);
}



- (void)appendTexture:(id<MTLTexture>)texture
{
    _textureLatest = texture;
    _textureCount += 1;
    
    [_texturesAccumulated setDrawableSize:CGSizeMake(texture.width, texture.height)];
}



- (void)accumulateTexture:(id<MTLTexture>)texture
                 onTarget:(NuoRenderPassTarget*)target
             withInFlight:(NSUInteger)inFlight
        withCommandBuffer:(id<MTLCommandBuffer>)commandBuffer
{
    [self appendTexture:texture];
    [self updateUniform:inFlight];
    
    id<MTLComputeCommandEncoder> encoder = [commandBuffer computeCommandEncoder];
    
    [encoder setTexture:_texturesAccumulated.targetTexture atIndex:0];
    [encoder setTexture:_textureLatest atIndex:1];
    [encoder setBuffer:_texCountBuffer[inFlight] offset:0 atIndex:0];
    
    MTLSize threadsPerThreadgroup = MTLSizeMake(8, 8, 1);
    MTLSize threadgroups = MTLSizeMake((texture.width  + threadsPerThreadgroup.width  - 1) / threadsPerThreadgroup.width,
                                       (texture.height + threadsPerThreadgroup.height - 1) / threadsPerThreadgroup.height, 1);
    
    [encoder setComputePipelineState:_pipelineState];
    [encoder dispatchThreadgroups:threadgroups threadsPerThreadgroup:threadsPerThreadgroup];
    [encoder endEncoding];
    
    [self setAccumulateTexture:target withCommandBuffer:commandBuffer];
}


- (void)setAccumulateTexture:(NuoRenderPassTarget*)target withCommandBuffer:(id<MTLCommandBuffer>)commandBuffer
{
    if (!target.manageTargetTexture)
    {
        id<MTLRenderCommandEncoder> accumulatePass = [target retainRenderPassEndcoder:commandBuffer];
        [_accumulatedMesh setModelTexture:_texturesAccumulated.targetTexture];
        [_accumulatedMesh drawMesh:accumulatePass indexBuffer:0];
        [target releaseRenderPassEndcoder];
    }
    else
    {
        id<MTLComputeCommandEncoder> encoder = [commandBuffer computeCommandEncoder];
        
        [encoder setTexture:target.targetTexture atIndex:0];
        [encoder setTexture:_texturesAccumulated.targetTexture atIndex:1];
        
        MTLSize threadsPerThreadgroup = MTLSizeMake(8, 8, 1);
        MTLSize threadgroups = MTLSizeMake((target.targetTexture.width  + threadsPerThreadgroup.width  - 1) / threadsPerThreadgroup.width,
                                           (target.targetTexture.height + threadsPerThreadgroup.height - 1) / threadsPerThreadgroup.height, 1);
        
        [encoder setComputePipelineState:_pipelineStateCopy];
        [encoder dispatchThreadgroups:threadgroups threadsPerThreadgroup:threadsPerThreadgroup];
        [encoder endEncoding];
    }
}



- (void)updateUniform:(NSInteger)bufferIndex
{
    memcpy(_texCountBuffer[bufferIndex].contents, &_textureCount, sizeof(uint32_t));
    [_texCountBuffer[bufferIndex] didModifyRange:NSMakeRange(0, sizeof(uint32_t))];
}




@end
