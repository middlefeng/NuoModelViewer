//
//  NuoBackdropMesh.m
//  ModelViewer
//
//  Created by Dong on 10/21/17.
//  Copyright © 2017 middleware. All rights reserved.
//

#import "NuoBackdropMesh.h"
#import "NuoTextureBase.h"

#include "NuoMathUtilities.h"



@implementation NuoBackdropMesh
{
    id<MTLTexture> _backdropTex;
    NSArray<id<MTLBuffer>>* _backdropTransformBuffers;
    id<MTLSamplerState> _samplerState;
}


- (instancetype)initWithCommandQueue:(id<MTLCommandQueue>)commandQueue withBackdrop:(id<MTLTexture>)backdrop
{
    NSUInteger backDropW = [backdrop width];
    NSUInteger backDropH = [backdrop height];
    
    CGFloat normalizedW = 1.0;
    CGFloat normalizedH = 1.0;
    
    CGFloat aspectRatio = ((float)backDropW) / ((float)backDropH);
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
        
        id<MTLBuffer> matrix[kInFlightBufferCount];
        for (uint i = 0; i < kInFlightBufferCount; ++i)
        {
            matrix[i] = [commandQueue. device newBufferWithLength:sizeof(NuoUniforms)
                                                          options:MTLResourceStorageModeManaged];
        }
        _backdropTransformBuffers = [[NSArray alloc] initWithObjects:matrix count:kInFlightBufferCount];
        
        _scale = 1.0;
        _translation = CGPointMake(0, 0);
    }
    
    return self;
}


- (void)updateUniform:(NSInteger)bufferIndex withDrawableSize:(CGSize)drawableSize
{
    NuoUniforms uniforms;
    
    vector_float3 scale = { _scale, _scale, 1.0 };
    vector_float3 translate = { _translation.x, _translation.y, 0.0 };
    
    float aspectRatio = drawableSize.width / drawableSize.height;
    if (aspectRatio > 1.0)
        scale.y *= aspectRatio;
    else
        scale.x /= aspectRatio;
    
    matrix_float4x4 matrix = matrix_uniform_scale_v(scale);
    matrix_float4x4 matrixTrans = matrix_translation(translate);
    
    uniforms.viewProjectionMatrix = matrix_multiply(matrixTrans, matrix);
    uniforms.viewMatrix = uniforms.viewProjectionMatrix;
    
    memcpy([_backdropTransformBuffers[bufferIndex] contents], &uniforms, sizeof(uniforms));
    [_backdropTransformBuffers[bufferIndex] didModifyRange:NSMakeRange(0, sizeof(uniforms))];
}


- (void)makePipelineAndSampler
{
    id<MTLLibrary> library = [self.commandQueue.device newDefaultLibrary];
    
    MTLRenderPipelineDescriptor *pipelineDescriptor = [MTLRenderPipelineDescriptor new];
    pipelineDescriptor.vertexFunction = [library newFunctionWithName:@"backdrop_project"];
    pipelineDescriptor.fragmentFunction = [library newFunctionWithName:@"backdrop_texutre"];
    pipelineDescriptor.sampleCount = 1;     // backdrop blends with no other fragments on one pixel
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
    
    self.depthStencilState = [self.commandQueue.device newDepthStencilStateWithDescriptor:depthStencilDescriptor];
    
    _samplerState = [[NuoTextureBase getInstance:self.commandQueue] textureSamplerState:YES];
}


- (void)drawMesh:(id<MTLRenderCommandEncoder>)renderPass indexBuffer:(NSInteger)index
{
    [renderPass setFrontFacingWinding:MTLWindingCounterClockwise];
    [renderPass setRenderPipelineState:self.renderPipelineState];
    [renderPass setDepthStencilState:self.depthStencilState];
    [renderPass setFragmentSamplerState:_samplerState atIndex:1];
    
    [renderPass setVertexBuffer:self.vertexBuffer offset:0 atIndex:0];
    [renderPass setVertexBuffer:_backdropTransformBuffers[index] offset:0 atIndex:3];
    
    [renderPass setFragmentTexture:_backdropTex atIndex:2];
    
    [renderPass drawIndexedPrimitives:MTLPrimitiveTypeTriangle
                           indexCount:[self.indexBuffer length] / sizeof(uint32_t)
                            indexType:MTLIndexTypeUInt32
                          indexBuffer:self.indexBuffer
                    indexBufferOffset:0];
}



@end
