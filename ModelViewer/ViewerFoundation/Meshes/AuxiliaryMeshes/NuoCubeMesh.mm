//
//  NuoMeshCube.m
//  ModelViewer
//
//  Created by dfeng on 3/3/17.
//  Copyright © 2017 middleware. All rights reserved.
//

#import "NuoCubeMesh.h"
#import "NuoMesh_Extension.h"

#import "NuoUniforms.h"
#import "NuoTextureBase.h"
#import "NuoBufferSwapChain.h"

#include "NuoTypes.h"
#include "NuoMathVector.h"




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
    NuoBufferSwapChain* _cubeMatrixBuffer;
    MTLPixelFormat _format;
    
    NuoMatrixFloat44 _cubeMatrix;
    NuoMatrixFloat44 _projectMatrix;
}



- (instancetype)initWithCommandQueue:(id<MTLCommandQueue>)commandQueue
{
    self = [super initWithCommandQueue:commandQueue
                    withVerticesBuffer:(void*)kVertices withLength:(size_t)sizeof(kVertices)
                           withIndices:(void*)kIndices withLength:(size_t)sizeof(kIndices)];
    
    if (self)
    {
        _cubeMatrix = NuoMatrixFloat44Identity;
        
        id<MTLDevice> device = commandQueue.device;
        _cubeMatrixBuffer = [[NuoBufferSwapChain alloc] initWithDevice:device
                                                        WithBufferSize:sizeof(NuoUniforms)
                                                           withOptions:MTLResourceStorageModeShared
                                                         withChainSize:kInFlightBufferCount];
            
        self.sampleCount = kSampleCount;
    }
    
    return self;
}


- (void)setProjectionMatrix:(const NuoMatrixFloat44&)projection
{
    _projectMatrix = projection;
}


- (void)updateUniform:(id<NuoRenderInFlight>)inFlight withTransform:(const NuoMatrixFloat44&)transform
{
    NuoUniforms uniforms;
    
    _cubeMatrix = NuoMatrixRotationAppend(_cubeMatrix, _rotationXDelta, _rotationYDelta);
    _rotationXDelta = 0;
    _rotationYDelta = 0;
    
    uniforms.viewProjectionMatrix = (_projectMatrix * _cubeMatrix)._m;
    uniforms.viewMatrix = _cubeMatrix._m;
    uniforms.viewMatrixInverse = _cubeMatrix.Inverse()._m;
    
    [_cubeMatrixBuffer updateBufferWithInFlight:inFlight withContent:&uniforms];
}



- (void)makeGPUStates
{
    [self makePipelineAndSampler:_format];
}


- (void)makePipelineAndSampler:(MTLPixelFormat)pixelFormat
{
    [self makeDepthStencilState];
    
    _format = pixelFormat;
    
    id<MTLLibrary> library = [self.device newDefaultLibrary];
    
    MTLRenderPipelineDescriptor *pipelineDescriptor = [MTLRenderPipelineDescriptor new];
    pipelineDescriptor.vertexFunction = [library newFunctionWithName:@"vertex_cube"];
    pipelineDescriptor.fragmentFunction = [library newFunctionWithName:@"fragment_cube"];
    pipelineDescriptor.sampleCount = self.sampleCount;
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
    
    self.depthStencilState = [self.device newDepthStencilStateWithDescriptor:depthStencilDescriptor];
    
    _samplerState = [[NuoTextureBase getInstance:self.commandQueue] textureSamplerState:NO];
}


- (void)drawMesh:(NuoRenderPassEncoder*)renderPass
{
    [renderPass setFrontFacingWinding:MTLWindingCounterClockwise];
    [renderPass setCullMode:MTLCullModeBack];
    [renderPass setRenderPipelineState:self.renderPipelineState];
    [renderPass setDepthStencilState:self.depthStencilState];
    
    [renderPass setVertexBuffer:self.vertexBuffer offset:0 atIndex:0];
    [renderPass setVertexBufferSwapChain:_cubeMatrixBuffer offset:0 atIndex:1];
    [renderPass setFragmentTexture:_cubeTexture atIndex:0];
    [renderPass setFragmentSamplerState:_samplerState atIndex:0];
    
    // 16-bit packed
    [renderPass drawPackedWithIndices:self.indexBuffer];
}


@end
