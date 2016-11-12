//
//  NotationRenderer.m
//  ModelViewer
//
//  Created by dfeng on 11/8/16.
//  Copyright © 2016 middleware. All rights reserved.
//


#import "NotationRenderer.h"

#import "NuoMesh.h"
#import "NuoMathUtilities.h"

#include "NuoModelArrow.h"
#include <memory>

#include "ModelUniforms.h"


@interface NotationRenderer()

@property (nonatomic, strong) NSArray<id<MTLBuffer>>* uniformBuffers;
@property (nonatomic, strong) id<MTLBuffer> lightBuffer;

@property (nonatomic, strong) NuoMesh* lightVector;

@end



@implementation NotationRenderer


- (instancetype)initWithDevice:(id<MTLDevice>)device
{
    self = [super initWithDevice:device];
    
    if (self)
    {
        [self makeResources];
        
        PNuoModelArrow arrow = std::make_shared<NuoModelArrow>(1.0, 0.2, 1.0, 0.3);
        arrow->CreateBuffer();
        
        NuoBox boundingBox = arrow->GetBoundingBox();
        
        NuoMeshBox* meshBounding = [[NuoMeshBox alloc] init];
        meshBounding.spanX = boundingBox._spanX;
        meshBounding.spanY = boundingBox._spanY;
        meshBounding.spanZ = boundingBox._spanZ;
        meshBounding.centerX = boundingBox._centerX;
        meshBounding.centerY = boundingBox._centerY;
        meshBounding.centerZ = boundingBox._centerZ;
        
        _lightVector = [[NuoMesh alloc] initWithDevice:self.device
                                    withVerticesBuffer:arrow->Ptr() withLength:arrow->Length()
                                           withIndices:arrow->IndicesPtr() withLength:arrow->IndicesLength()];
        
        MTLRenderPipelineDescriptor* pipelineDesc = [_lightVector makePipelineStateDescriptor];
        pipelineDesc.sampleCount = 1;
        
        [_lightVector setBoundingBox:meshBounding];
        [_lightVector makePipelineState:pipelineDesc];
        [_lightVector makeDepthStencilState];
    }
    
    return self;
}


- (void)makeResources
{
    id<MTLBuffer> buffers[kInFlightBufferCount];
    for (size_t i = 0; i < kInFlightBufferCount; ++i)
    {
        id<MTLBuffer> uniformBuffer = [self.device newBufferWithLength:sizeof(ModelUniforms)
                                                               options:MTLResourceOptionCPUCacheModeDefault];
        buffers[i] = uniformBuffer;
        
        NSString* label = [NSString stringWithFormat:@"Uniforms %lu", i];
        [uniformBuffer setLabel:label];
    }
    
    _uniformBuffers = [[NSArray alloc] initWithObjects:buffers[0], buffers[1], buffers[2], nil];
    
    LightingUniforms lightUniform;
    lightUniform.lightVector = {  0.13, 0.72, 0.68, 0.0 };
    
    _lightBuffer = [self.device newBufferWithLength:sizeof(LightingUniforms)
                                            options:MTLResourceOptionCPUCacheModeDefault];
    
    memcpy([_lightBuffer contents], &lightUniform, sizeof(LightingUniforms));
}


- (void)updateUniformsForView
{
    const vector_float4 startVec = { 0, 0, 1, 0 };
    matrix_float4x4 rotationMatrix = matrix_rotate(startVec, _rotateX, _rotateY);
    
    NuoMeshBox* bounding = _lightVector.boundingBox;
    
    const vector_float3 translationToCenter =
    {
        - bounding.centerX,
        - bounding.centerY,
        - bounding.centerZ
    };
    
    float zoom = -60.0;
    
    const matrix_float4x4 modelCenteringMatrix = matrix_float4x4_translation(translationToCenter);
    const matrix_float4x4 modelMatrix = matrix_multiply(rotationMatrix, modelCenteringMatrix);
    
    float modelSpan = std::max(bounding.spanZ, bounding.spanX);
    modelSpan = std::max(bounding.spanY, modelSpan);
    
    const float modelNearest = - modelSpan / 2.0;
    const float cameraDefaultDistance = (modelNearest - modelSpan);
    const float cameraDistance = cameraDefaultDistance + zoom * modelSpan / 20.0f;
    
    const vector_float3 cameraTranslation =
    {
        0, 0, cameraDistance
    };
    
    const matrix_float4x4 viewMatrix = matrix_float4x4_translation(cameraTranslation);
    
    const CGSize drawableSize = self.renderTarget.drawableSize;
    const float aspect = drawableSize.width / drawableSize.height;
    const float near = -cameraDistance - modelSpan / 2.0 + 0.01;
    const float far = near + modelSpan + 0.02;
    const matrix_float4x4 projectionMatrix = matrix_float4x4_perspective(aspect, (2 * M_PI) / 30, near, far);
    
    ModelUniforms uniforms;
    uniforms.modelViewMatrix = matrix_multiply(viewMatrix, modelMatrix);
    uniforms.modelViewProjectionMatrix = matrix_multiply(projectionMatrix, uniforms.modelViewMatrix);
    uniforms.normalMatrix = matrix_float4x4_extract_linear(uniforms.modelViewMatrix);
    
    memcpy([self.uniformBuffers[self.bufferIndex] contents], &uniforms, sizeof(uniforms));
}



- (void)drawWithCommandBuffer:(id<MTLCommandBuffer>)commandBuffer
{
    [super drawWithCommandBuffer:commandBuffer];
    
    id<MTLRenderCommandEncoder> renderPass = self.lastRenderPass;
    self.lastRenderPass = nil;
    
    const float lightSettingAreaFactor = 0.2;
    
    CGSize drawableSize = self.renderTarget.drawableSize;
    MTLViewport viewPort;
    viewPort.originX = drawableSize.width * (1 - lightSettingAreaFactor);
    viewPort.originY = drawableSize.height * (1 - lightSettingAreaFactor);
    viewPort.width = drawableSize.width * lightSettingAreaFactor;
    viewPort.height = drawableSize.height * lightSettingAreaFactor;
    viewPort.znear = 0.0;
    viewPort.zfar = 1.0;
    [renderPass setViewport:viewPort];
    
    [self updateUniformsForView];
    [renderPass setVertexBuffer:self.uniformBuffers[self.bufferIndex] offset:0 atIndex:1];
    [renderPass setVertexBuffer:self.lightBuffer offset:0 atIndex:2];
    
    [_lightVector drawMesh:renderPass];
    [renderPass endEncoding];
}


@end
