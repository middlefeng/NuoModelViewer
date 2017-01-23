//
//  NuoMeshTexMatieraled.m
//  ModelViewer
//
//  Created by dfeng on 9/7/16.
//  Copyright © 2016 middleware. All rights reserved.
//

#import "NuoMeshTexMatieraled.h"
#import "NuoTextureBase.h"


@implementation NuoMeshTexMatieraled
{
    id<MTLTexture> _textureOpacity;
    id<MTLTexture> _textureBump;
}


- (instancetype)initWithDevice:(id<MTLDevice>)device
            withVerticesBuffer:(void*)buffer withLength:(size_t)length
                   withIndices:(void*)indices withLength:(size_t)indicesLength
{
    self = [super initWithDevice:device
              withVerticesBuffer:buffer
                      withLength:length
                     withIndices:indices
                      withLength:indicesLength];
    
    return self;
}



- (void)makeTextureOpacity:(NSString*)texPath withCommandQueue:(id<MTLCommandQueue>)queue
{
    NuoTextureBase* textureBase = [NuoTextureBase getInstance:self.device];
    NuoTexture* texture = [textureBase texture2DWithImageNamed:texPath mipmapped:YES
                                             checkTransparency:NO commandQueue:queue];
    _textureOpacity = texture.texture;
}



- (void)makeTextureBump:(NSString*)texPath withCommandQueue:(id<MTLCommandQueue>)queue
{
    NuoTextureBase* textureBase = [NuoTextureBase getInstance:self.device];
    NuoTexture* texture = [textureBase texture2DWithImageNamed:texPath mipmapped:YES
                                             checkTransparency:NO commandQueue:queue];
    _textureBump = texture.texture;
}


- (void)makePipelineShadowState
{
    id<MTLLibrary> library = [self.device newDefaultLibrary];
    
    NSString* shadowShader = _textureBump ? @"vertex_shadow_tex_materialed_bump" : @"vertex_shadow_tex_materialed";
    
    MTLRenderPipelineDescriptor *shadowPipelineDescriptor = [MTLRenderPipelineDescriptor new];
    shadowPipelineDescriptor.vertexFunction = [library newFunctionWithName:shadowShader];
    shadowPipelineDescriptor.fragmentFunction = [library newFunctionWithName:@"fragment_shadow"];;
    shadowPipelineDescriptor.sampleCount = kSampleCount;
    shadowPipelineDescriptor.colorAttachments[0].pixelFormat = MTLPixelFormatInvalid;
    shadowPipelineDescriptor.depthAttachmentPixelFormat = MTLPixelFormatDepth32Float;
    
    NSError *error = nil;
    self.shadowPipelineState = [self.device newRenderPipelineStateWithDescriptor:shadowPipelineDescriptor
                                                                           error:&error];
}



- (MTLRenderPipelineDescriptor*)makePipelineStateDescriptor:(BOOL)ignoreTextureAlpha
{
    id<MTLLibrary> library = [self.device newDefaultLibrary];
    
    MTLRenderPipelineDescriptor *pipelineDescriptor = [MTLRenderPipelineDescriptor new];
    pipelineDescriptor.depthAttachmentPixelFormat = MTLPixelFormatDepth32Float;
    pipelineDescriptor.sampleCount = kSampleCount;
    
    if (!_textureBump)
    {
        pipelineDescriptor.vertexFunction = [library newFunctionWithName:@"vertex_project_tex_materialed"];
        if (ignoreTextureAlpha)
        {
            if (_textureOpacity)
                pipelineDescriptor.fragmentFunction = [library newFunctionWithName:@"fragment_light_tex_materialed_tex_opacity"];
            else
                pipelineDescriptor.fragmentFunction = [library newFunctionWithName:@"fragment_light_tex_materialed"];
        }
        else
        {
            pipelineDescriptor.fragmentFunction = [library newFunctionWithName:@"fragment_light_tex_a_materialed"];
        }
    }
    else
    {
        pipelineDescriptor.vertexFunction = [library newFunctionWithName:@"vertex_tex_materialed_tangent"];
        if (ignoreTextureAlpha)
        {
            if (_textureOpacity)
                pipelineDescriptor.fragmentFunction = [library newFunctionWithName:@"fragment_tex_materialed_tex_opacity_bump"];
            else
                pipelineDescriptor.fragmentFunction = [library newFunctionWithName:@"fragment_tex_materialed_bump"];
        }
        else
        {
            pipelineDescriptor.fragmentFunction = [library newFunctionWithName:@"fragment_tex_a_materialed_bump"];
        }
    }
    
    pipelineDescriptor.colorAttachments[0].pixelFormat = MTLPixelFormatBGRA8Unorm;
    MTLRenderPipelineColorAttachmentDescriptor* colorAttachment = pipelineDescriptor.colorAttachments[0];
    colorAttachment.blendingEnabled = YES;
    colorAttachment.rgbBlendOperation = MTLBlendOperationAdd;
    colorAttachment.alphaBlendOperation = MTLBlendOperationAdd;
    colorAttachment.sourceRGBBlendFactor = MTLBlendFactorSourceAlpha;
    colorAttachment.destinationRGBBlendFactor = MTLBlendFactorOneMinusSourceAlpha;
    colorAttachment.destinationAlphaBlendFactor = MTLBlendFactorOneMinusSourceAlpha;
    
    unsigned int offset = 0;
    unsigned int attrIndex = 0;
    
    MTLVertexDescriptor* vertexDescriptor = [MTLVertexDescriptor new];
    vertexDescriptor.attributes[attrIndex].format = MTLVertexFormatFloat4;      // position
    vertexDescriptor.attributes[attrIndex].offset = offset; offset += 16;
    vertexDescriptor.attributes[attrIndex].bufferIndex = 0; ++attrIndex;
    vertexDescriptor.attributes[attrIndex].format = MTLVertexFormatFloat4;      // normal
    vertexDescriptor.attributes[attrIndex].offset = offset; offset += 16;
    vertexDescriptor.attributes[attrIndex].bufferIndex = 0; ++attrIndex;
    if (_textureBump)
    {
        vertexDescriptor.attributes[attrIndex].format = MTLVertexFormatFloat4;  // tangent
        vertexDescriptor.attributes[attrIndex].offset = offset; offset += 16;
        vertexDescriptor.attributes[attrIndex].bufferIndex = 0; ++attrIndex;
        vertexDescriptor.attributes[attrIndex].format = MTLVertexFormatFloat4;  // bi-tangent
        vertexDescriptor.attributes[attrIndex].offset = offset; offset += 16;
        vertexDescriptor.attributes[attrIndex].bufferIndex = 0; ++attrIndex;
    }
    vertexDescriptor.attributes[attrIndex].format = MTLVertexFormatFloat2;      // texCoord
    vertexDescriptor.attributes[attrIndex].offset = offset; offset += 16;
    vertexDescriptor.attributes[attrIndex].bufferIndex = 0; ++attrIndex;
    vertexDescriptor.attributes[attrIndex].format = MTLVertexFormatFloat3;      // diffuse
    vertexDescriptor.attributes[attrIndex].offset = offset; offset += 16;
    vertexDescriptor.attributes[attrIndex].bufferIndex = 0; ++attrIndex;
    vertexDescriptor.attributes[attrIndex].format = MTLVertexFormatFloat3;      // ambient
    vertexDescriptor.attributes[attrIndex].offset = offset; offset += 16;
    vertexDescriptor.attributes[attrIndex].bufferIndex = 0; ++attrIndex;
    vertexDescriptor.attributes[attrIndex].format = MTLVertexFormatFloat3;      // specular
    vertexDescriptor.attributes[attrIndex].offset = offset; offset += 16;
    vertexDescriptor.attributes[attrIndex].bufferIndex = 0; ++attrIndex;
    vertexDescriptor.attributes[attrIndex].format = MTLVertexFormatFloat2;      // shinessDisolve
    vertexDescriptor.attributes[attrIndex].offset = offset; offset += 16;
    vertexDescriptor.attributes[attrIndex].bufferIndex = 0; ++attrIndex;
    
    vertexDescriptor.layouts[0].stride = offset;
    vertexDescriptor.layouts[0].stepRate = 1;
    vertexDescriptor.layouts[0].stepFunction = MTLVertexStepFunctionPerVertex;
    
    pipelineDescriptor.vertexDescriptor = vertexDescriptor;
    
    return pipelineDescriptor;
}


- (void)drawMesh:(id<MTLRenderCommandEncoder>) renderPass
{
    [renderPass setFrontFacingWinding:MTLWindingCounterClockwise];
    [renderPass setRenderPipelineState:self.renderPipelineState];
    [renderPass setDepthStencilState:self.depthStencilState];
    
    [renderPass setVertexBuffer:self.vertexBuffer offset:0 atIndex:0];
    [renderPass setFragmentSamplerState:self.samplerState atIndex:1];
    
    NSUInteger texBufferIndex = 1;
    [renderPass setFragmentTexture:self.diffuseTex atIndex:texBufferIndex++];
    if (_textureOpacity)
        [renderPass setFragmentTexture:_textureOpacity atIndex:texBufferIndex++];
    if (_textureBump)
        [renderPass setFragmentTexture:_textureBump atIndex:texBufferIndex];
    
    [renderPass drawIndexedPrimitives:MTLPrimitiveTypeTriangle
                           indexCount:[self.indexBuffer length] / sizeof(uint32_t)
                            indexType:MTLIndexTypeUInt32
                          indexBuffer:self.indexBuffer
                    indexBufferOffset:0];
}




@end






@implementation NuoMeshMatieraled
{
    BOOL _hasTransparent;
}



- (instancetype)initWithDevice:(id<MTLDevice>)device
            withVerticesBuffer:(void*)buffer withLength:(size_t)length
                   withIndices:(void*)indices withLength:(size_t)indicesLength
{
    self = [super initWithDevice:device
              withVerticesBuffer:buffer
                      withLength:length
                     withIndices:indices
                      withLength:indicesLength];
    
    return self;
}




- (MTLRenderPipelineDescriptor*)makePipelineStateDescriptor
{
    id<MTLLibrary> library = [self.device newDefaultLibrary];
    
    MTLRenderPipelineDescriptor *pipelineDescriptor = [MTLRenderPipelineDescriptor new];
    pipelineDescriptor.vertexFunction = [library newFunctionWithName:@"vertex_project_materialed"];
    pipelineDescriptor.fragmentFunction = [library newFunctionWithName:@"fragment_light_materialed"];
    pipelineDescriptor.depthAttachmentPixelFormat = MTLPixelFormatDepth32Float;
    pipelineDescriptor.sampleCount = kSampleCount;
    
    pipelineDescriptor.colorAttachments[0].pixelFormat = MTLPixelFormatBGRA8Unorm;
    MTLRenderPipelineColorAttachmentDescriptor* colorAttachment = pipelineDescriptor.colorAttachments[0];
    colorAttachment.blendingEnabled = YES;
    colorAttachment.rgbBlendOperation = MTLBlendOperationAdd;
    colorAttachment.alphaBlendOperation = MTLBlendOperationAdd;
    colorAttachment.destinationRGBBlendFactor = MTLBlendFactorOneMinusSourceAlpha;
    colorAttachment.destinationAlphaBlendFactor = MTLBlendFactorOneMinusSourceAlpha;
    
    MTLVertexDescriptor* vertexDescriptor = [MTLVertexDescriptor new];
    vertexDescriptor.attributes[0].format = MTLVertexFormatFloat4;
    vertexDescriptor.attributes[0].offset = 0;
    vertexDescriptor.attributes[0].bufferIndex = 0;
    vertexDescriptor.attributes[1].format = MTLVertexFormatFloat4;
    vertexDescriptor.attributes[1].offset = 16;
    vertexDescriptor.attributes[1].bufferIndex = 0;
    vertexDescriptor.attributes[2].format = MTLVertexFormatFloat3;
    vertexDescriptor.attributes[2].offset = 32;
    vertexDescriptor.attributes[2].bufferIndex = 0;
    vertexDescriptor.attributes[3].format = MTLVertexFormatFloat3;
    vertexDescriptor.attributes[3].offset = 48;
    vertexDescriptor.attributes[3].bufferIndex = 0;
    vertexDescriptor.attributes[4].format = MTLVertexFormatFloat3;
    vertexDescriptor.attributes[4].offset = 64;
    vertexDescriptor.attributes[4].bufferIndex = 0;
    vertexDescriptor.attributes[5].format = MTLVertexFormatFloat2;
    vertexDescriptor.attributes[5].offset = 80;
    vertexDescriptor.attributes[5].bufferIndex = 0;
    
    vertexDescriptor.layouts[0].stride = 96;
    vertexDescriptor.layouts[0].stepRate = 1;
    vertexDescriptor.layouts[0].stepFunction = MTLVertexStepFunctionPerVertex;
    
    pipelineDescriptor.vertexDescriptor = vertexDescriptor;
    
    return pipelineDescriptor;
}



- (BOOL)hasTransparency
{
    return _hasTransparent;
}



- (void)setTransparency:(BOOL)transparent
{
    _hasTransparent = transparent;
}



@end


