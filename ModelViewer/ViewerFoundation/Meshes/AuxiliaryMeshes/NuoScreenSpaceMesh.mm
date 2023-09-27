//
//  NuoScreenSpaceMesh.m
//  ModelViewer
//
//  Created by Dong on 9/30/17.
//  Copyright © 2017 middleware. All rights reserved.
//

#import "NuoScreenSpaceMesh.h"
#import "NuoMesh_Extension.h"
#import "NuoTextureBase.h"




@implementation NuoScreenSpaceMesh


- (instancetype)initWithCommandQueue:(id<MTLCommandQueue>)commandQueue
{
    float vertices[] =
    {
        -1, 1,  0, 1.0,    0, 0, 0, 0,
        -1, -1, 0, 1.0,    0, 1, 0, 0,
        1, -1,  0, 1.0,    1, 1, 0, 0,
        1, 1,   0, 1.0,    1, 0, 0, 0,
    };
    
    uint32_t indices[] =
    {
        0, 1, 2,
        2, 3, 0
    };
    
    self = [super initWithCommandQueue:commandQueue
                    withVerticesBuffer:(void*)vertices withLength:(size_t)sizeof(vertices)
                           withIndices:(void*)indices withLength:(size_t)sizeof(indices)];
    
    return self;
}


- (void)makePipelineAndSampler:(MTLPixelFormat)pixelFormat
           withFragementShader:(NSString*)shaderName
                 withBlendMode:(ScreenSpaceBlendMode)mode
{
    id<MTLLibrary> library = [self library];
    
    MTLRenderPipelineDescriptor *pipelineDescriptor = [MTLRenderPipelineDescriptor new];
    pipelineDescriptor.vertexFunction = [library newFunctionWithName:@"texture_project"];
    pipelineDescriptor.fragmentFunction = [library newFunctionWithName:shaderName];
    pipelineDescriptor.rasterSampleCount = self.sampleCount;
    
    auto* colorAttachment = pipelineDescriptor.colorAttachments[0];
    
    colorAttachment.pixelFormat = pixelFormat;
    
    if (mode != kBlend_None &&
        mode != kBlend_AlphaOverflow) // shader implemented mode, turn off pipeline blending
    {
        colorAttachment.blendingEnabled = YES;
        colorAttachment.rgbBlendOperation = MTLBlendOperationAdd;
        colorAttachment.alphaBlendOperation = MTLBlendOperationAdd;
        colorAttachment.sourceRGBBlendFactor = MTLBlendFactorOne;    // the shader returns pre-multiplied color
        
        if (mode == kBlend_Alpha)
        {
            colorAttachment.destinationRGBBlendFactor = MTLBlendFactorOneMinusSourceAlpha;
            colorAttachment.destinationAlphaBlendFactor = MTLBlendFactorOneMinusSourceAlpha;
        }
        else
        {
            colorAttachment.destinationRGBBlendFactor = MTLBlendFactorOne;
            colorAttachment.destinationAlphaBlendFactor = MTLBlendFactorOneMinusSourceAlpha;
        }
    }
    
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
    // leave all fragement shader related setup to the outter draw function (or subclass)
    
    [renderPass pushParameterState:@"Screen space"];
    
    [renderPass setFrontFacingWinding:MTLWindingCounterClockwise];
    [renderPass setRenderPipelineState:self.renderPipelineState];
    [renderPass setDepthStencilState:self.depthStencilState];
    [renderPass setFragmentSamplerState:_samplerState atIndex:0];
    
    [renderPass setVertexBuffer:self.vertexBuffer offset:0 atIndex:0];
    [renderPass drawWithIndices:self.indexBuffer];
    
    [renderPass popParameterState];
}



@end
