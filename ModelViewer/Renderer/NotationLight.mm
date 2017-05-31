//
//  NotationLight.m
//  ModelViewer
//
//  Created by middleware on 11/13/16.
//  Copyright © 2017 middleware. All rights reserved.
//

#import "NotationLight.h"

#import "NuoMesh.h"
#import "NuoMathUtilities.h"

#include "NuoModelArrow.h"
#include <memory>

#include "NuoUniforms.h"
#include "NuoMeshUniform.h"

#import "LightSource.h"



@interface NotationLight()


@property (nonatomic, strong) NSArray<id<MTLBuffer>>* characterUniformBuffers;
@property (nonatomic, weak) id<MTLDevice> device;

@property (nonatomic, strong) NuoMesh* lightVector;


@end



@implementation NotationLight


- (instancetype)initWithDevice:(id<MTLDevice>)device isBold:(BOOL)bold
{
    self = [super init];
    
    if (self)
    {
        _device = device;
        
        [self makeResources];
        
        float bodyLength = bold ? 1.2 : 1.0;
        float bodyRadius = bold ? 0.24 : 0.2;
        float headLength = bold ? 1.2 : 1.0;
        float headRadius = bold ? 0.36 : 0.3;
        
        PNuoModelArrow arrow = std::make_shared<NuoModelArrow>(bodyLength, bodyRadius, headLength, headRadius);
        arrow->CreateBuffer();
        
        NuoBox boundingBox = arrow->GetBoundingBox();
        
        NuoMeshBox* meshBounding = [[NuoMeshBox alloc] init];
        meshBounding.span.x = boundingBox._spanX;
        meshBounding.span.y = boundingBox._spanY;
        meshBounding.span.z = boundingBox._spanZ;
        meshBounding.center.x = boundingBox._centerX;
        meshBounding.center.y = boundingBox._centerY;
        meshBounding.center.z = boundingBox._centerZ;
        
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
    id<MTLBuffer> characters[kInFlightBufferCount];
    for (size_t i = 0; i < kInFlightBufferCount; ++i)
    {
        id<MTLBuffer> characterUniformBuffers = [self.device newBufferWithLength:sizeof(ModelCharacterUniforms)
                                                                         options:MTLResourceOptionCPUCacheModeDefault];
        characters[i] = characterUniformBuffers;
    }
    
    _characterUniformBuffers = [[NSArray alloc] initWithObjects:characters[0], characters[1], characters[2], nil];
}


- (void)updateUniformsForView:(unsigned int)inFlight
{
    LightSource* desc = _lightSourceDesc;
    NuoMeshBox* bounding = _lightVector.boundingBox;
    
    const vector_float3 translationToCenter =
    {
        - bounding.center.x,
        - bounding.center.y,
        - bounding.center.z + bounding.span.z / 2.0f
    };
    
    const matrix_float4x4 modelCenteringMatrix = matrix_translation(translationToCenter);
    const matrix_float4x4 modelMatrix = matrix_rotation_append(modelCenteringMatrix, desc.lightingRotationX, desc.lightingRotationY);
    [_lightVector updateUniform:inFlight withTransform:modelMatrix];
    
    ModelCharacterUniforms characters;
    characters.opacity = _selected ? 1.0f : 0.1f;
    
    memcpy([self.characterUniformBuffers[inFlight] contents], &characters, sizeof(characters));
}


- (void)setSelected:(BOOL)selected
{
    _selected = selected;
    
    [_lightVector setTransparency:!_selected];
    [_lightVector makeDepthStencilState];
}


- (CGPoint)headPointProjected
{
    LightSource* desc = _lightSourceDesc;
    
    matrix_float4x4 rotationMatrix = matrix_rotate(desc.lightingRotationX,
                                                   desc.lightingRotationY);
    
    const vector_float4 startVec = { 0, 0, 1, 1 };
    vector_float4 projected = matrix_multiply(rotationMatrix, startVec);
    
    return CGPointMake(projected.x / projected.w, projected.y / projected.w);
}



- (void)drawWithRenderPass:(id<MTLRenderCommandEncoder>)renderPass
              withInFlight:(unsigned int)inFlight
{
    [self updateUniformsForView:inFlight];
    [renderPass setFragmentBuffer:self.characterUniformBuffers[inFlight] offset:0 atIndex:1];
    
    // the light vector notation does not have varying uniform,
    // use only the 0th buffer
    //
    [_lightVector drawMesh:renderPass indexBuffer:inFlight];
}



@end
