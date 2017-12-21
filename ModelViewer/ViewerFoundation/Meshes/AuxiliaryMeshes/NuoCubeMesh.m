//
//  NuoMeshCube.m
//  ModelViewer
//
//  Created by dfeng on 3/3/17.
//  Copyright © 2017 middleware. All rights reserved.
//

#import "NuoCubeMesh.h"
#import "NuoUniforms.h"
#import "NuoMathUtilities.h"
#import "NuoTextureBase.h"

#include "NuoTypes.h"




static float kVertices[] =
{
    // + Y
    -0.5,  0.5,  0.5, 1.0,  0.0, -1.0,  0.0, 0.0,
    0.5,  0.5,  0.5, 1.0,  0.0, -1.0,  0.0, 0.0,
    0.5,  0.5, -0.5, 1.0,  0.0, -1.0,  0.0, 0.0,
    -0.5,  0.5, -0.5, 1.0,  0.0, -1.0,  0.0, 0.0,
    // -Y
    -0.5, -0.5, -0.5, 1.0,  0.0,  1.0,  0.0, 0.0,
    0.5, -0.5, -0.5, 1.0,  0.0,  1.0,  0.0, 0.0,
    0.5, -0.5,  0.5, 1.0,  0.0,  1.0,  0.0, 0.0,
    -0.5, -0.5,  0.5, 1.0,  0.0,  1.0,  0.0, 0.0,
    // +Z
    -0.5, -0.5,  0.5, 1.0,  0.0,  0.0, -1.0, 0.0,
    0.5, -0.5,  0.5, 1.0,  0.0,  0.0, -1.0, 0.0,
    0.5,  0.5,  0.5, 1.0,  0.0,  0.0, -1.0, 0.0,
    -0.5,  0.5,  0.5, 1.0,  0.0,  0.0, -1.0, 0.0,
    // -Z
    0.5, -0.5, -0.5, 1.0,  0.0,  0.0,  1.0, 0.0,
    -0.5, -0.5, -0.5, 1.0,  0.0,  0.0,  1.0, 0.0,
    -0.5,  0.5, -0.5, 1.0,  0.0,  0.0,  1.0, 0.0,
    0.5,  0.5, -0.5, 1.0,  0.0,  0.0,  1.0, 0.0,
    // -X
    -0.5, -0.5, -0.5, 1.0,  1.0,  0.0,  0.0, 0.0,
    -0.5, -0.5,  0.5, 1.0,  1.0,  0.0,  0.0, 0.0,
    -0.5,  0.5,  0.5, 1.0,  1.0,  0.0,  0.0, 0.0,
    -0.5,  0.5, -0.5, 1.0,  1.0,  0.0,  0.0, 0.0,
    // +X
    0.5, -0.5,  0.5, 1.0, -1.0,  0.0,  0.0, 0.0,
    0.5, -0.5, -0.5, 1.0, -1.0,  0.0,  0.0, 0.0,
    0.5,  0.5, -0.5, 1.0, -1.0,  0.0,  0.0, 0.0,
    0.5,  0.5,  0.5, 1.0, -1.0,  0.0,  0.0, 0.0,
};



static uint16_t kIndices[] =
{
    0,  3,  2,  2,  1,  0,
    4,  7,  6,  6,  5,  4,
    8, 11, 10, 10,  9,  8,
    12, 15, 14, 14, 13, 12,
    16, 19, 18, 18, 17, 16,
    20, 23, 22, 22, 21, 20,
};


@implementation NuoCubeMesh
{
    __weak id<MTLSamplerState> _samplerState;
    NSArray<id<MTLBuffer>>* _cubeMatrixBuffer;
    
    matrix_float4x4 _cubeMatrix;
    matrix_float4x4 _projectMatrix;
}



- (instancetype)initWithCommandQueue:(id<MTLCommandQueue>)commandQueue
{
    self = [super initWithCommandQueue:commandQueue
                    withVerticesBuffer:(void*)kVertices withLength:(size_t)sizeof(kVertices)
                           withIndices:(void*)kIndices withLength:(size_t)sizeof(kIndices)];
    
    if (self)
    {
        _cubeMatrix = matrix_identity_float4x4;
        
        {
            id<MTLBuffer> matrix[kInFlightBufferCount];
            id<MTLDevice> device = commandQueue.device;
            
            for (uint i = 0; i < kInFlightBufferCount; ++i)
            {
                matrix[i] = [device newBufferWithLength:sizeof(NuoUniforms)
                                                options:MTLResourceOptionCPUCacheModeDefault];
            }
            _cubeMatrixBuffer = [[NSArray alloc] initWithObjects:matrix count:kInFlightBufferCount];
        }
    }
    
    return self;
}


- (void)setProjectionMatrix:(matrix_float4x4)projection
{
    _projectMatrix = projection;
}


- (void)updateUniform:(NSInteger)bufferIndex withTransform:(matrix_float4x4)transform
{
    NuoUniforms uniforms;
    
    _cubeMatrix = matrix_rotation_append(_cubeMatrix, _rotationXDelta, _rotationYDelta);
    _rotationXDelta = 0;
    _rotationYDelta = 0;
    
    uniforms.viewProjectionMatrix = matrix_multiply(_projectMatrix, _cubeMatrix);
    uniforms.viewMatrix = _cubeMatrix;
    
    memcpy([_cubeMatrixBuffer[bufferIndex] contents], &uniforms, sizeof(uniforms));
}


- (void)makePipelineAndSampler:(MTLPixelFormat)pixelFormat
{
    id<MTLLibrary> library = [self.commandQueue.device newDefaultLibrary];
    
    MTLRenderPipelineDescriptor *pipelineDescriptor = [MTLRenderPipelineDescriptor new];
    pipelineDescriptor.vertexFunction = [library newFunctionWithName:@"vertex_cube"];
    pipelineDescriptor.fragmentFunction = [library newFunctionWithName:@"fragment_cube"];
    pipelineDescriptor.sampleCount = kSampleCount;
    pipelineDescriptor.colorAttachments[0].pixelFormat = pixelFormat;
    pipelineDescriptor.depthAttachmentPixelFormat = MTLPixelFormatDepth32Float;
    
    MTLVertexDescriptor* vertexDescriptor = [MTLVertexDescriptor new];
    vertexDescriptor.attributes[0].format = MTLVertexFormatFloat4;
    vertexDescriptor.attributes[0].offset = 0;
    vertexDescriptor.attributes[0].bufferIndex = 0;
    vertexDescriptor.attributes[1].format = MTLVertexFormatFloat4;
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
    
    _samplerState = [[NuoTextureBase getInstance:self.commandQueue] textureSamplerState:NO];
}


- (void)drawMesh:(id<MTLRenderCommandEncoder>)renderPass indexBuffer:(NSInteger)index
{
    [renderPass setFrontFacingWinding:MTLWindingCounterClockwise];
    [renderPass setCullMode:MTLCullModeBack];
    [renderPass setRenderPipelineState:self.renderPipelineState];
    [renderPass setDepthStencilState:self.depthStencilState];
    
    [renderPass setVertexBuffer:self.vertexBuffer offset:0 atIndex:0];
    [renderPass setVertexBuffer:_cubeMatrixBuffer[index] offset:0 atIndex:1];
    [renderPass setFragmentTexture:_cubeTexture atIndex:0];
    [renderPass setFragmentSamplerState:_samplerState atIndex:0];
    
    [renderPass drawIndexedPrimitives:MTLPrimitiveTypeTriangle
                           indexCount:[self.indexBuffer length] / sizeof(uint16_t)
                            indexType:MTLIndexTypeUInt16
                          indexBuffer:self.indexBuffer
                    indexBufferOffset:0];
}


@end
