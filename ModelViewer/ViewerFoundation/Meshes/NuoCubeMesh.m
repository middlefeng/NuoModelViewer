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
    id<MTLSamplerState> _samplerState;
    NSArray<id<MTLBuffer>>* _cubeMatrixBuffer;
    
    matrix_float4x4 _cubeMatrix;
    matrix_float4x4 _projectMatrix;
}



- (instancetype)initWithDevice:(id<MTLDevice>)device
{
    self = [super initWithDevice:device
              withVerticesBuffer:(void*)kVertices withLength:(size_t)sizeof(kVertices)
                     withIndices:(void*)kIndices withLength:(size_t)sizeof(kIndices)];
    
    if (self)
    {
        _cubeMatrix = matrix_identity_float4x4;
        
        {
            id<MTLBuffer> matrix[kInFlightBufferCount];
            for (uint i = 0; i < kInFlightBufferCount; ++i)
            {
                matrix[i] = [device newBufferWithLength:sizeof(ModelUniforms)
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


- (void)updateUniform:(NSInteger)bufferIndex
{
    ModelUniforms uniforms;
    
    _cubeMatrix = matrix_rotation_append(_cubeMatrix, _rotationXDelta, _rotationYDelta);
    _rotationXDelta = 0;
    _rotationYDelta = 0;
    
    uniforms.modelViewProjectionMatrix = matrix_multiply(_cubeMatrix, _projectMatrix);
    uniforms.modelViewMatrix = _cubeMatrix;
    
    memcpy([_cubeMatrixBuffer[bufferIndex] contents], &uniforms, sizeof(uniforms));
}


- (void)makePipelineAndSampler:(MTLPixelFormat)pixelFormat
{
    id<MTLLibrary> library = [self.device newDefaultLibrary];
    
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
    vertexDescriptor.attributes[1].format = MTLVertexFormatFloat2;
    vertexDescriptor.attributes[1].offset = 16;
    vertexDescriptor.attributes[1].bufferIndex = 0;
    vertexDescriptor.layouts[0].stride = 32;
    vertexDescriptor.layouts[0].stepRate = 1;
    vertexDescriptor.layouts[0].stepFunction = MTLVertexStepFunctionPerVertex;
    
    pipelineDescriptor.vertexDescriptor = vertexDescriptor;
    
    [self makePipelineState:pipelineDescriptor];
    
    MTLDepthStencilDescriptor *depthStencilDescriptor = [MTLDepthStencilDescriptor new];
    depthStencilDescriptor.depthCompareFunction = MTLCompareFunctionLess;
    depthStencilDescriptor.depthWriteEnabled = NO;
    
    self.depthStencilState = [self.device newDepthStencilStateWithDescriptor:depthStencilDescriptor];
    
    // create sampler state
    MTLSamplerDescriptor *samplerDesc = [MTLSamplerDescriptor new];
    samplerDesc.sAddressMode = MTLSamplerAddressModeRepeat;
    samplerDesc.tAddressMode = MTLSamplerAddressModeRepeat;
    samplerDesc.minFilter = MTLSamplerMinMagFilterNearest;
    samplerDesc.magFilter = MTLSamplerMinMagFilterNearest;
    samplerDesc.mipFilter = MTLSamplerMipFilterNotMipmapped;
    _samplerState = [self.device newSamplerStateWithDescriptor:samplerDesc];
}


- (void)drawMesh:(id<MTLRenderCommandEncoder>)renderPass indexBuffer:(NSInteger)index
{
    [renderPass setFrontFacingWinding:MTLWindingCounterClockwise];
    [renderPass setRenderPipelineState:self.renderPipelineState];
    [renderPass setDepthStencilState:self.depthStencilState];
    
    [renderPass setVertexBuffer:self.vertexBuffer offset:0 atIndex:0];
    [renderPass setVertexBuffer:_cubeMatrixBuffer[index] offset:0 atIndex:1];
    [renderPass setFragmentTexture:_cubeTexture atIndex:0];
    [renderPass setFragmentSamplerState:_samplerState atIndex:0];
    
    [renderPass drawIndexedPrimitives:MTLPrimitiveTypeTriangle
                           indexCount:[self.indexBuffer length] / sizeof(uint32_t)
                            indexType:MTLIndexTypeUInt32
                          indexBuffer:self.indexBuffer
                    indexBufferOffset:0];
}


@end
