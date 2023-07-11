//
//  NuoBackdropMesh.m
//  ModelViewer
//
//  Created by Dong on 10/21/17.
//  Copyright © 2017 middleware. All rights reserved.
//

#import "NuoBackdropMesh.h"
#import "NuoMesh_Extension.h"
#import "NuoTextureBase.h"
#import "NuoBufferSwapChain.h"

#include "NuoTypes.h"




@implementation NuoBackdropMesh
{
    id<MTLTexture> _backdropTex;
    NuoBufferSwapChain* _backdropTransformBuffers;
    id<MTLSamplerState> _samplerState;
}


- (instancetype)initWithCommandQueue:(id<MTLCommandQueue>)commandQueue withBackdrop:(id<MTLTexture>)backdrop
{
    NSUInteger backDropW = [backdrop width];
    NSUInteger backDropH = [backdrop height];
    
    float normalizedW = 1.0;
    float normalizedH = 1.0;
    
    float aspectRatio = ((float)backDropW) / ((float)backDropH);
    if (aspectRatio > 1.0)
        normalizedW = normalizedH * aspectRatio;
    else
        normalizedH = normalizedW / aspectRatio;
    
    float vertices[] =
    {
        -normalizedW, normalizedH,  0, 1.0,    0, 1, 0, 0,
        -normalizedW, -normalizedH, 0, 1.0,    0, 0, 0, 0,
        normalizedW, -normalizedH,  0, 1.0,    1, 0, 0, 0,
        normalizedW, normalizedH,   0, 1.0,    1, 1, 0, 0,
    };
    
    uint32_t indices[] =
    {
        0, 1, 2,
        2, 3, 0
    };
    
    self = [super initWithCommandQueue:commandQueue
                    withVerticesBuffer:(void*)vertices withLength:(size_t)sizeof(vertices)
                           withIndices:(void*)indices withLength:(size_t)sizeof(indices)];
    
    if (self)
    {
        _backdropTex = backdrop;
        _backdropTransformBuffers = [[NuoBufferSwapChain alloc] initWithDevice:commandQueue.device
                                                                WithBufferSize:sizeof(NuoUniforms)
                                                                   withOptions:MTLResourceStorageModeManaged
                                                                 withChainSize:kInFlightBufferCount
                                                                      withName:@"Backdrop Transform"];
        
        _scale = 1.0;
        _translation = CGPointMake(0, 0);
    }
    
    return self;
}


- (void)updateUniform:(id<NuoRenderInFlight>)inFlight withDrawableSize:(CGSize)drawableSize
{
    NuoUniforms uniforms;
    
    NuoVectorFloat3 scale(_scale, _scale, 1.0);
    NuoVectorFloat3 translate(_translation.x, _translation.y, 0.0);
    
    float aspectRatio = drawableSize.width / drawableSize.height;
    if (aspectRatio > 1.0)
        scale.y(scale.y() * aspectRatio);
    else
        scale.x(scale.x() / aspectRatio);
    
    NuoMatrixFloat44 matrix = NuoMatrixScale(scale);
    NuoMatrixFloat44 matrixTrans = NuoMatrixTranslation(translate);
    
    uniforms.viewProjectionMatrix = (matrixTrans * matrix)._m;
    uniforms.viewMatrix = uniforms.viewProjectionMatrix;
    
    [_backdropTransformBuffers updateBufferWithInFlight:inFlight withContent:&uniforms];
}


- (void)makePipelineAndSampler
{
    id<MTLLibrary> library = [self library];
    
    MTLRenderPipelineDescriptor *pipelineDescriptor = [MTLRenderPipelineDescriptor new];
    pipelineDescriptor.vertexFunction = [library newFunctionWithName:@"backdrop_project"];
    pipelineDescriptor.fragmentFunction = [library newFunctionWithName:@"backdrop_texutre"];
    pipelineDescriptor.rasterSampleCount = 1;     // backdrop blends with no other fragments on one pixel
    pipelineDescriptor.colorAttachments[0].pixelFormat = MTLPixelFormatBGRA8Unorm;
    
    pipelineDescriptor.depthAttachmentPixelFormat = MTLPixelFormatDepth32Float;
    
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
    
    pipelineDescriptor.vertexDescriptor = vertexDescriptor;
    
    [self makePipelineState:pipelineDescriptor];
    
    MTLDepthStencilDescriptor *depthStencilDescriptor = [MTLDepthStencilDescriptor new];
    depthStencilDescriptor.depthCompareFunction = MTLCompareFunctionAlways;
    depthStencilDescriptor.depthWriteEnabled = NO;
    
    self.depthStencilState = [self.device newDepthStencilStateWithDescriptor:depthStencilDescriptor];
    
    _samplerState = [[NuoTextureBase getInstance:self.commandQueue] textureSamplerState:YES];
}


- (void)drawMesh:(NuoRenderPassEncoder*)renderPass
{
    [renderPass pushParameterState:@"Backdrop mesh"];
    
    [renderPass setFrontFacingWinding:MTLWindingCounterClockwise];
    [renderPass setRenderPipelineState:self.renderPipelineState];
    [renderPass setDepthStencilState:self.depthStencilState];
    [renderPass setFragmentSamplerState:_samplerState atIndex:1];
    
    [renderPass setVertexBuffer:self.vertexBuffer offset:0 atIndex:0];
    [renderPass setVertexBufferInFlight:_backdropTransformBuffers offset:0 atIndex:3];
    
    [renderPass setFragmentTexture:_backdropTex atIndex:2];
    
    [renderPass drawWithIndices:self.indexBuffer];
    
    [renderPass popParameterState];
}



@end
