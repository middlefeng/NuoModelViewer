//
//  NuoMeshTextured.m
//  ModelViewer
//
//  Created by middleware on 9/7/16.
//  Copyright © 2016 middleware. All rights reserved.
//

#import "NuoMeshTextured.h"
#import "NuoTextureBase.h"
#import <CoreImage/CoreImage.h>




static CIContext* sCIContext = nil;




@implementation NuoMeshTextured



- (instancetype)initWithDevice:(id<MTLDevice>)device
            withVerticesBuffer:(void*)buffer withLength:(size_t)length
                   withIndices:(void*)indices withLength:(size_t)indicesLength
{
    if ((self = [super initWithDevice:device withVerticesBuffer:buffer withLength:length
                          withIndices:indices withLength:indicesLength]))
    {
        _hasTransparency = NO;
    }
    
    return self;
}



- (void)drawMesh:(id<MTLRenderCommandEncoder>) renderPass
{
    [renderPass setFrontFacingWinding:MTLWindingCounterClockwise];
    [renderPass setRenderPipelineState:self.renderPipelineState];
    [renderPass setDepthStencilState:self.depthStencilState];
    
    [renderPass setVertexBuffer:self.vertexBuffer offset:0 atIndex:0];
    [renderPass setFragmentTexture:self.diffuseTex atIndex:1];
    [renderPass setFragmentSamplerState:self.samplerState atIndex:0];
    
    [renderPass drawIndexedPrimitives:MTLPrimitiveTypeTriangle
                           indexCount:[self.indexBuffer length] / sizeof(uint32_t)
                            indexType:MTLIndexTypeUInt32
                          indexBuffer:self.indexBuffer
                    indexBufferOffset:0];
}




- (void)makeTexture:(NSString*)texPath checkTransparency:(BOOL)check
{
    NuoTextureBase* textureBase = [NuoTextureBase getInstance:self.device];
    NuoTexture* texture = [textureBase texture2DWithImageNamed:texPath mipmapped:NO checkTransparency:check];
    
    assert(texture.texture != nil);
    
    _diffuseTex = texture.texture;
    _hasTransparency = texture.hasTransparency;
    
    // create sampler state
    MTLSamplerDescriptor *samplerDesc = [MTLSamplerDescriptor new];
    samplerDesc.sAddressMode = MTLSamplerAddressModeRepeat;
    samplerDesc.tAddressMode = MTLSamplerAddressModeRepeat;
    samplerDesc.minFilter = MTLSamplerMinMagFilterLinear;
    samplerDesc.magFilter = MTLSamplerMinMagFilterLinear;
    samplerDesc.mipFilter = MTLSamplerMipFilterNotMipmapped;
    _samplerState = [self.device newSamplerStateWithDescriptor:samplerDesc];
}


- (MTLRenderPipelineDescriptor*)makePipelineStateDescriptor
{
    id<MTLLibrary> library = [self.device newDefaultLibrary];
    
    MTLRenderPipelineDescriptor *pipelineDescriptor = [MTLRenderPipelineDescriptor new];
    pipelineDescriptor.vertexFunction = [library newFunctionWithName:@"vertex_project_textured"];
    pipelineDescriptor.fragmentFunction = [library newFunctionWithName:@"fragment_light_textured"];
    pipelineDescriptor.depthAttachmentPixelFormat = MTLPixelFormatDepth32Float;
    pipelineDescriptor.sampleCount = kSampleCount;
    
    pipelineDescriptor.colorAttachments[0].pixelFormat = MTLPixelFormatBGRA8Unorm;
    MTLRenderPipelineColorAttachmentDescriptor* colorAttachment = pipelineDescriptor.colorAttachments[0];
    if (_hasTransparency)
    {
        colorAttachment.blendingEnabled = YES;
        colorAttachment.rgbBlendOperation = MTLBlendOperationAdd;
        colorAttachment.alphaBlendOperation = MTLBlendOperationAdd;
        colorAttachment.sourceRGBBlendFactor = MTLBlendFactorSourceAlpha;
        colorAttachment.destinationRGBBlendFactor = MTLBlendFactorOneMinusSourceAlpha;
        colorAttachment.destinationAlphaBlendFactor = MTLBlendFactorOneMinusSourceAlpha;
    }
    
    MTLVertexDescriptor* vertexDescriptor = [MTLVertexDescriptor new];
    vertexDescriptor.attributes[0].format = MTLVertexFormatFloat4;
    vertexDescriptor.attributes[0].offset = 0;
    vertexDescriptor.attributes[0].bufferIndex = 0;
    vertexDescriptor.attributes[0].format = MTLVertexFormatFloat4;
    vertexDescriptor.attributes[0].offset = 16;
    vertexDescriptor.attributes[0].bufferIndex = 0;
    vertexDescriptor.attributes[0].format = MTLVertexFormatFloat2;
    vertexDescriptor.attributes[0].offset = 32;
    vertexDescriptor.attributes[0].bufferIndex = 0;
    vertexDescriptor.layouts[0].stride = 48;
    vertexDescriptor.layouts[0].stepRate = 1;
    vertexDescriptor.layouts[0].stepFunction = MTLVertexStepFunctionPerVertex;
    
    pipelineDescriptor.vertexDescriptor = vertexDescriptor;
    
    return pipelineDescriptor;
}

- (void)makePipelineShadowState
{
    id<MTLLibrary> library = [self.device newDefaultLibrary];
    
    MTLRenderPipelineDescriptor *shadowPipelineDescriptor = [MTLRenderPipelineDescriptor new];
    shadowPipelineDescriptor.vertexFunction = [library newFunctionWithName:@"vertex_shadow_textured"];
    shadowPipelineDescriptor.fragmentFunction = [library newFunctionWithName:@"fragment_shadow_textured"];;
    shadowPipelineDescriptor.sampleCount = kSampleCount;
    shadowPipelineDescriptor.colorAttachments[0].pixelFormat = MTLPixelFormatInvalid;
    shadowPipelineDescriptor.depthAttachmentPixelFormat = MTLPixelFormatDepth32Float;
    
    NSError *error = nil;
    self.shadowPipelineState = [self.device newRenderPipelineStateWithDescriptor:shadowPipelineDescriptor
                                                                           error:&error];
}

- (void)setTransparency:(BOOL)transparent
{
    _hasTransparency = transparent;
}




@end
