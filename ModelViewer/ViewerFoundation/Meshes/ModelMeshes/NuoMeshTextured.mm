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
    }
    
    return self;
}



- (void)shareResourcesFrom:(NuoMesh*)mesh
{
    NuoMeshTextured* meshTextured = (NuoMeshTextured*)mesh;
    
    [super shareResourcesFrom:mesh];
    _diffuseTex = meshTextured.diffuseTex;
    _samplerState = meshTextured.samplerState;
    _hasTextureTransparency = meshTextured.hasTextureTransparency;
}


- (instancetype)cloneForMode:(NuoMeshModeShaderParameter)mode
{
    return self;
}


- (void)drawMesh:(id<MTLRenderCommandEncoder>)renderPass indexBuffer:(NSInteger)index
{
    [renderPass setFrontFacingWinding:MTLWindingCounterClockwise];
    [renderPass setRenderPipelineState:self.renderPipelineState];
    [renderPass setDepthStencilState:self.depthStencilState];
    
    [renderPass setVertexBuffer:self.vertexBuffer offset:0 atIndex:0];
    [renderPass setVertexBuffer:self.transformBuffers[index] offset:0 atIndex:3];
    [renderPass setFragmentTexture:self.diffuseTex atIndex:2];
    [renderPass setFragmentSamplerState:self.samplerState atIndex:1];
    
    [renderPass drawIndexedPrimitives:MTLPrimitiveTypeTriangle
                           indexCount:[self.indexBuffer length] / sizeof(uint32_t)
                            indexType:MTLIndexTypeUInt32
                          indexBuffer:self.indexBuffer
                    indexBufferOffset:0];
}




- (void)makeTexture:(NSString*)texPath checkTransparency:(BOOL)check withCommandQueue:(id<MTLCommandQueue>)queue
{
    NuoTextureBase* textureBase = [NuoTextureBase getInstance:self.device];
    NuoTexture* texture = [textureBase texture2DWithImageNamed:texPath mipmapped:YES
                                             checkTransparency:check commandQueue:queue];
    
    assert(texture.texture != nil);
    
    _diffuseTex = texture.texture;
    _hasTextureTransparency = texture.hasTransparency;
    [self setTransparency:texture.hasTransparency];
    
    _samplerState = [[NuoTextureBase getInstance:self.device] textureSamplerState:YES];
}


- (MTLRenderPipelineDescriptor*)makePipelineStateDescriptor
{
    id<MTLLibrary> library = [self.device newDefaultLibrary];
    
    BOOL pcss = self.shadowOptionPCSS;
    BOOL pcf = self.shadowOptionPCF;
    
    MTLFunctionConstantValues* funcConstant = [MTLFunctionConstantValues new];
    NuoMeshModeShaderParameter meshMode = kMeshMode_Normal;
    [funcConstant setConstantValue:&pcss type:MTLDataTypeBool atIndex:4];
    [funcConstant setConstantValue:&pcf type:MTLDataTypeBool atIndex:5];
    [funcConstant setConstantValue:&meshMode type:MTLDataTypeInt atIndex:6];
    
    MTLRenderPipelineDescriptor *pipelineDescriptor = [MTLRenderPipelineDescriptor new];
    pipelineDescriptor.vertexFunction = [library newFunctionWithName:@"vertex_project_textured"];
    pipelineDescriptor.fragmentFunction = [library newFunctionWithName:@"fragment_light_textured"
                                                        constantValues:funcConstant error:nil];
    pipelineDescriptor.depthAttachmentPixelFormat = MTLPixelFormatDepth32Float;
    pipelineDescriptor.sampleCount = self.sampleCount;
    
    pipelineDescriptor.colorAttachments[0].pixelFormat = MTLPixelFormatBGRA8Unorm;
    MTLRenderPipelineColorAttachmentDescriptor* colorAttachment = pipelineDescriptor.colorAttachments[0];
    if ([self hasTransparency])
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


- (void)makePipelineScreenSpaceState
{
    [self makePipelineScreenSpaceStateWithVertexShader:@"vertex_screen_space_textured"
                                    withFragemtnShader:@"fragement_screen_space_textured"];
}


- (void)makePipelineShadowState
{
    [super makePipelineShadowState:@"vertex_shadow_textured"];
}




@end
