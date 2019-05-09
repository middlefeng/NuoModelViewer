//
//  NuoMeshTextured.m
//  ModelViewer
//
//  Created by middleware on 9/7/16.
//  Copyright © 2016 middleware. All rights reserved.
//

#import "NuoMeshTextured.h"
#import "NuoMesh_Extension.h"

#import "NuoTextureBase.h"
#import <CoreImage/CoreImage.h>




static CIContext* sCIContext = nil;




@implementation NuoMeshTextured



- (instancetype)initWithCommandQueue:(id<MTLCommandQueue>)commandQueue
                  withVerticesBuffer:(void*)buffer withLength:(size_t)length
                         withIndices:(void*)indices withLength:(size_t)indicesLength
{
    if ((self = [super initWithCommandQueue:commandQueue
                         withVerticesBuffer:buffer withLength:length
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
    NuoMeshTextured* mesh = [NuoMeshTextured new];
    [mesh shareResourcesFrom:self];
    
    [mesh makePipelineShadowState];
    [mesh makePipelineState];
    [mesh makeDepthStencilState];
    
    return mesh;
}


- (void)drawMesh:(NuoRenderPassEncoder*)renderPass
{
    [renderPass pushParameterState:@"Mesh Textured"];
    
    [renderPass setFrontFacingWinding:MTLWindingCounterClockwise];
    [renderPass setRenderPipelineState:self.renderPipelineState];
    [renderPass setDepthStencilState:self.depthStencilState];
    
    [renderPass setVertexBuffer:self.vertexBuffer offset:0 atIndex:0];
    [renderPass setVertexBufferSwapChain:self.transformBuffers offset:0 atIndex:3];
    [renderPass setFragmentTexture:self.diffuseTex atIndex:4];
    [renderPass setFragmentSamplerState:self.samplerState atIndex:1];
    
    [renderPass drawWithIndices:self.indexBuffer];
    
    [renderPass popParameterState];
}


- (void)drawScreenSpace:(NuoRenderPassEncoder*)renderPass
{
    [renderPass pushParameterState:@"Mesh Textured Screen Space"];
    
    [renderPass setFragmentTexture:self.diffuseTex atIndex:0];
    [renderPass setFragmentSamplerState:self.samplerState atIndex:0];
    
    [super drawScreenSpace:renderPass];
    
    [renderPass popParameterState];
}



- (void)makeTexture:(NSString*)texPath checkTransparency:(BOOL)check
{
    NuoTextureBase* textureBase = [NuoTextureBase getInstance:self.commandQueue];
    NuoTexture* texture = [textureBase texture2DWithImageNamed:texPath mipmapped:YES
                                             checkTransparency:check];
    
    assert(texture.texture != nil);
    
    _diffuseTex = texture.texture;
    _hasTextureTransparency = texture.hasTransparency;
    [self setTransparency:texture.hasTransparency];
    
    _samplerState = [[NuoTextureBase getInstance:self.commandQueue] textureSamplerState:YES];
}


- (MTLRenderPipelineDescriptor*)makePipelineStateDescriptor
{
    id<MTLLibrary> library = [self.device newDefaultLibrary];
    
    BOOL pcss = self.shadowOptionPCSS;
    BOOL pcf = self.shadowOptionPCF;
    BOOL rayTracing = self.shadowOptionRayTracing;
    
    MTLFunctionConstantValues* funcConstant = [MTLFunctionConstantValues new];
    NuoMeshModeShaderParameter meshMode = kMeshMode_Normal;
    BOOL physicalReflection = NO;
    
    [funcConstant setConstantValue:&physicalReflection type:MTLDataTypeBool atIndex:2];
    [funcConstant setConstantValue:&pcss type:MTLDataTypeBool atIndex:4];
    [funcConstant setConstantValue:&pcf type:MTLDataTypeBool atIndex:5];
    [funcConstant setConstantValue:&rayTracing type:MTLDataTypeBool atIndex:7];
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
    [super makePipelineShadowState:@"vertex_simple_textured"];
}



-  (void)appendWorldBuffers:(const NuoMatrixFloat44&)transform toBuffers:(GlobalBuffers*)buffers
{
    GlobalBuffers oneBuffer;
    [super appendWorldBuffers:transform toBuffers:&oneBuffer];
    
    auto existingItem = std::find(buffers->_textureMap.begin(),
                                  buffers->_textureMap.end(),
                                  (__bridge void*)_diffuseTex);
    
    size_t currentIndex = 0;
    if (existingItem == buffers->_textureMap.end())
    {
        buffers->_textureMap.push_back((__bridge void*)_diffuseTex);
        currentIndex = buffers->_textureMap.size() - 1;
    }
    else
    {
        currentIndex = existingItem - buffers->_textureMap.begin();
    }
    
    for (NuoRayTracingMaterial& item : oneBuffer._materials)
    {
        assert(item.diffuseTex == -2);
        item.diffuseTex = (int)currentIndex;
    }
    
    buffers->Union(oneBuffer);
    
    // no handling to the array exceeding preset number of shader
    // argument bindings
    assert(buffers->_textureMap.size() < kTextureBindingsCap);
}




@end
