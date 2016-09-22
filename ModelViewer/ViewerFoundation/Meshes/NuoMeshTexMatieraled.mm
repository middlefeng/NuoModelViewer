//
//  NuoMeshTexMatieraled.m
//  ModelViewer
//
//  Created by dfeng on 9/7/16.
//  Copyright © 2016 middleware. All rights reserved.
//

#import "NuoMeshTexMatieraled.h"



@implementation NuoMeshTexMatieraled
{
    id<MTLTexture> _textureOpacity;
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



- (void)makeTextureOpacity:(NSString*)texPath
{
    _textureOpacity = [self texture2DWithImageNamed:texPath mipmapped:NO checkTransparency:NO];
}



- (MTLRenderPipelineDescriptor*)makePipelineStateDescriptor:(BOOL)ignoreTextureAlpha
{
    id<MTLLibrary> library = [self.device newDefaultLibrary];
    
    MTLRenderPipelineDescriptor *pipelineDescriptor = [MTLRenderPipelineDescriptor new];
    pipelineDescriptor.depthAttachmentPixelFormat = MTLPixelFormatDepth32Float;
    pipelineDescriptor.sampleCount = sSampleCount;
    
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
    
    
    pipelineDescriptor.colorAttachments[0].pixelFormat = MTLPixelFormatBGRA8Unorm;
    MTLRenderPipelineColorAttachmentDescriptor* colorAttachment = pipelineDescriptor.colorAttachments[0];
    colorAttachment.blendingEnabled = YES;
    colorAttachment.rgbBlendOperation = MTLBlendOperationAdd;
    colorAttachment.alphaBlendOperation = MTLBlendOperationAdd;
    colorAttachment.sourceRGBBlendFactor = MTLBlendFactorSourceAlpha;
    colorAttachment.destinationRGBBlendFactor = MTLBlendFactorOneMinusSourceAlpha;
    colorAttachment.destinationAlphaBlendFactor = MTLBlendFactorOneMinusSourceAlpha;
    
    MTLVertexDescriptor* vertexDescriptor = [MTLVertexDescriptor new];
    vertexDescriptor.attributes[0].format = MTLVertexFormatFloat4;
    vertexDescriptor.attributes[0].offset = 0;
    vertexDescriptor.attributes[0].bufferIndex = 0;
    vertexDescriptor.attributes[1].format = MTLVertexFormatFloat4;
    vertexDescriptor.attributes[1].offset = 16;
    vertexDescriptor.attributes[1].bufferIndex = 0;
    vertexDescriptor.attributes[2].format = MTLVertexFormatFloat2;
    vertexDescriptor.attributes[2].offset = 32;
    vertexDescriptor.attributes[2].bufferIndex = 0;
    vertexDescriptor.attributes[3].format = MTLVertexFormatFloat3;
    vertexDescriptor.attributes[3].offset = 48;
    vertexDescriptor.attributes[3].bufferIndex = 0;
    vertexDescriptor.attributes[4].format = MTLVertexFormatFloat3;
    vertexDescriptor.attributes[4].offset = 64;
    vertexDescriptor.attributes[4].bufferIndex = 0;
    vertexDescriptor.attributes[5].format = MTLVertexFormatFloat3;
    vertexDescriptor.attributes[5].offset = 80;
    vertexDescriptor.attributes[5].bufferIndex = 0;
    vertexDescriptor.attributes[6].format = MTLVertexFormatFloat2;
    vertexDescriptor.attributes[6].offset = 96;
    vertexDescriptor.attributes[6].bufferIndex = 0;
    
    vertexDescriptor.layouts[0].stride = 112;
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
    [renderPass setFragmentSamplerState:self.samplerState atIndex:0];
    
    [renderPass setFragmentTexture:self.diffuseTex atIndex:0];
    if (_textureOpacity)
        [renderPass setFragmentTexture:_textureOpacity atIndex:1];
    
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
    pipelineDescriptor.sampleCount = sSampleCount;
    
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


