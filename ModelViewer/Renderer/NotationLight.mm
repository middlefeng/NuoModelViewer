//
//  NotationLight.m
//  ModelViewer
//
//  Created by middleware on 11/13/16.
//  Copyright © 2016 middleware. All rights reserved.
//

#import "NotationLight.h"

#import "NuoMesh.h"
#import "NuoMathUtilities.h"

#include "NuoModelArrow.h"
#include <memory>

#include "ModelUniforms.h"



@interface NotationLight()


@property (nonatomic, strong) NSArray<id<MTLBuffer>>* uniformBuffers;
@property (nonatomic, strong) NSArray<id<MTLBuffer>>* characterUniformBuffers;
@property (nonatomic, weak) id<MTLDevice> device;

@property (nonatomic, strong) NuoMesh* lightVector;


@end



@implementation NotationLight


- (instancetype)initWithDevice:(id<MTLDevice>)device
{
    self = [super init];
    
    if (self)
    {
        _device = device;
        
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


- (NuoMeshBox*)boundingBox
{
    return _lightVector.boundingBox;
}


- (void)makeResources
{
    id<MTLBuffer> buffers[kInFlightBufferCount];
    id<MTLBuffer> characters[kInFlightBufferCount];
    for (size_t i = 0; i < kInFlightBufferCount; ++i)
    {
        id<MTLBuffer> uniformBuffer = [self.device newBufferWithLength:sizeof(ModelUniforms)
                                                               options:MTLResourceOptionCPUCacheModeDefault];
        buffers[i] = uniformBuffer;
        
        id<MTLBuffer> characterUniformBuffers = [self.device newBufferWithLength:sizeof(ModelCharacterUniforms)
                                                                         options:MTLResourceOptionCPUCacheModeDefault];
        characters[i] = characterUniformBuffers;
    }
    
    _uniformBuffers = [[NSArray alloc] initWithObjects:buffers[0], buffers[1], buffers[2], nil];
    _characterUniformBuffers = [[NSArray alloc] initWithObjects:characters[0], characters[1], characters[2], nil];
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
        - bounding.centerZ + bounding.spanZ / 2.0f
    };
    
    const matrix_float4x4 modelCenteringMatrix = matrix_float4x4_translation(translationToCenter);
    const matrix_float4x4 modelMatrix = matrix_multiply(rotationMatrix, modelCenteringMatrix);
    
    ModelUniforms uniforms;
    uniforms.modelViewMatrix = matrix_multiply(_viewMatrix, modelMatrix);
    uniforms.modelViewProjectionMatrix = matrix_multiply(_projMatrix, uniforms.modelViewMatrix);
    uniforms.normalMatrix = matrix_float4x4_extract_linear(uniforms.modelViewMatrix);
    
    memcpy([self.uniformBuffers[self.bufferIndex] contents], &uniforms, sizeof(uniforms));
    
    ModelCharacterUniforms characters;
    characters.opacity = _selected ? 1.0f : 0.1f;
    
    memcpy([self.characterUniformBuffers[self.bufferIndex] contents], &characters, sizeof(characters));
}


- (void)setSelected:(BOOL)selected
{
    _selected = selected;
    
    [_lightVector setTransparency:!_selected];
    [_lightVector makeDepthStencilState];
}


- (CGPoint)headPointProjected
{
    const vector_float4 startVec = { 0, 0, 1, 1 };
    matrix_float4x4 rotationMatrix = matrix_rotate(startVec, _rotateX, _rotateY);
    vector_float4 projected = matrix_multiply(rotationMatrix, startVec);
    
    return CGPointMake(projected.x / projected.w, projected.y / projected.w);
}



- (void)drawWithRenderPass:(id<MTLRenderCommandEncoder>)renderPass
{
    [self updateUniformsForView];
    [renderPass setVertexBuffer:self.uniformBuffers[self.bufferIndex] offset:0 atIndex:1];
    [renderPass setFragmentBuffer:self.characterUniformBuffers[self.bufferIndex] offset:0 atIndex:1];
    [_lightVector drawMesh:renderPass];
}



- (void)drawablePresented
{
    _bufferIndex = (_bufferIndex + 1) % kInFlightBufferCount;
}


@end
