//
//  NuoTextureMesh.m
//  ModelViewer
//
//  Created by middleware on 11/3/16.
//  Copyright © 2017 middleware. All rights reserved.
//

#import "NuoTextureMesh.h"
#import "NuoTextureBase.h"

struct TextureMixFragment
{
    float mixProportion;
};


struct ClearFragment
{
    vector_float4 clearColor;
};


@implementation NuoTextureMesh
{
    NSArray<id<MTLBuffer>>* _textureMixBuffer;
    id<MTLBuffer> _clearColorBuffer;
}


- (instancetype)initWithCommandQueue:(id<MTLCommandQueue>)commandQueue
{
    self = [super initWithCommandQueue:commandQueue];
    
    if (self)
    {
        id<MTLBuffer> buffers[kInFlightBufferCount];
        for (size_t i = 0; i < kInFlightBufferCount; ++i)
            buffers[i] = [commandQueue.device newBufferWithLength:sizeof(TextureMixFragment)
                                                          options:MTLResourceOptionCPUCacheModeDefault];
        _textureMixBuffer = [[NSArray alloc] initWithObjects:buffers count:kInFlightBufferCount];
        
        _clearColorBuffer = [commandQueue.device newBufferWithLength:sizeof(ClearFragment)
                                                             options:MTLResourceOptionCPUCacheModeDefault];
    }
    
    return self;
}


- (void)setClearColor:(MTLClearColor)clearColor
{
    _clearColor = clearColor;
    vector_float4 color4 = { (float)clearColor.red, (float)clearColor.green, (float)clearColor.blue, (float)clearColor.alpha };
    ClearFragment clearParam;
    clearParam.clearColor = color4;
    memcpy(_clearColorBuffer.contents, &clearParam, sizeof(ClearFragment));
}


- (void)makePipelineAndSampler:(MTLPixelFormat)pixelFormat withSampleCount:(NSUInteger)sampleCount
{
    NSString* shaderName = _auxiliaryTexture ? @"fragment_texture_mix" :
                                               @"fragment_texture";
    
    if (_clearWithColor)
        shaderName = @"fragment_clear";
     
    [self makePipelineAndSampler:pixelFormat withFragementShader:shaderName
                 withSampleCount:sampleCount withBlendMode:kBlend_None];
    
    //[self makePipelineScreenSpaceStateWithVertexShader:@"texture_project"
    //                                withFragemtnShader:@"fragement_clear_screen_space"];
    {
        id<MTLLibrary> library = [self.device newDefaultLibrary];
        
        MTLRenderPipelineDescriptor *screenSpacePipelineDescriptor = [MTLRenderPipelineDescriptor new];
        screenSpacePipelineDescriptor.vertexFunction = [library newFunctionWithName:@"texture_project"];
        screenSpacePipelineDescriptor.fragmentFunction = [library newFunctionWithName:@"fragement_clear_screen_space"];
        screenSpacePipelineDescriptor.sampleCount = kSampleCount;
        
        MTLVertexDescriptor* vertexDescriptor = [MTLVertexDescriptor new];
        vertexDescriptor.attributes[0].format = MTLVertexFormatFloat4;
        vertexDescriptor.attributes[0].offset = 0;
        vertexDescriptor.attributes[0].bufferIndex = 0;
        vertexDescriptor.attributes[1].format = MTLVertexFormatFloat2;
        vertexDescriptor.attributes[1].offset = 16;
        vertexDescriptor.attributes[1].bufferIndex = 0;
        vertexDescriptor.layouts[0].stride = 32;
        vertexDescriptor.layouts[0].stepRate = 1;
        vertexDescriptor.layouts[0].stepFunction = MTLVertexStepFunctionPerVertex;
        
        screenSpacePipelineDescriptor.vertexDescriptor = vertexDescriptor;
        
        // blending is turned OFF for all attachments, see comments to "FragementScreenSpace"
        //
        screenSpacePipelineDescriptor.colorAttachments[0].pixelFormat = MTLPixelFormatRGBA16Float;
        screenSpacePipelineDescriptor.colorAttachments[1].pixelFormat = MTLPixelFormatRGBA16Float;
        screenSpacePipelineDescriptor.colorAttachments[2].pixelFormat = MTLPixelFormatRGBA16Float;
        screenSpacePipelineDescriptor.colorAttachments[3].pixelFormat = MTLPixelFormatR8Unorm;
        
        for (int i = 0; i < 3; ++i)
            screenSpacePipelineDescriptor.colorAttachments[i].blendingEnabled = NO;
        
        screenSpacePipelineDescriptor.depthAttachmentPixelFormat = MTLPixelFormatDepth32Float;
        
        NSError *error = nil;
        self.screenSpacePipelineState = [self.device newRenderPipelineStateWithDescriptor:screenSpacePipelineDescriptor
                                                                                error:&error];
    }
}

/*
- (void)makePipelineScreenSpaceState
{
    [self makePipelineScreenSpaceStateWithVertexShader:@"texture_project"
                                    withFragemtnShader:@"fragement_clear_screen_space"];
}*/


- (void)updateUniform:(NSInteger)bufferIndex withTransform:(matrix_float4x4)transform
{
    [super updateUniform:bufferIndex withTransform:transform];
    
    if (_auxiliaryTexture)
    {
        TextureMixFragment mixFragment;
        mixFragment.mixProportion = _auxiliaryProportion;
        memcpy(_textureMixBuffer[bufferIndex].contents, &mixFragment, sizeof(TextureMixFragment));
    }
}


- (void)drawMesh:(id<MTLRenderCommandEncoder>)renderPass indexBuffer:(NSInteger)index
{
    [self updateUniform:index withTransform:matrix_identity_float4x4];
    
    assert((!_modelTexture) == _clearWithColor);
    
    if (_modelTexture)
    {
        [renderPass setFragmentTexture:_modelTexture atIndex:0];
    }
    else
    {
        [renderPass setFragmentBuffer:_clearColorBuffer offset:0 atIndex:0];
    }
    
    if (_auxiliaryTexture)
    {
        [renderPass setFragmentTexture:_auxiliaryTexture atIndex:1];
        [renderPass setFragmentBuffer:_textureMixBuffer[index] offset:0 atIndex:0];
    }
    
    [super drawMesh:renderPass indexBuffer:index];
}


- (void)drawScreenSpace:(id<MTLRenderCommandEncoder>)renderPass indexBuffer:(NSInteger)index
{
    [renderPass setFrontFacingWinding:MTLWindingCounterClockwise];
    [renderPass setRenderPipelineState:self.screenSpacePipelineState];
    [renderPass setDepthStencilState:self.depthStencilState];
    
    [renderPass setVertexBuffer:self.vertexBuffer offset:0 atIndex:0];
    [renderPass setFragmentBuffer:_clearColorBuffer offset:0 atIndex:0];
    [renderPass drawIndexedPrimitives:MTLPrimitiveTypeTriangle
                           indexCount:[self.indexBuffer length] / sizeof(uint32_t)
                            indexType:MTLIndexTypeUInt32
                          indexBuffer:self.indexBuffer
                    indexBufferOffset:0];
}


@end
