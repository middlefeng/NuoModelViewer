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

#import "NuoLightSource.h"



@interface NotationLight()


@property (nonatomic, strong) id<MTLBuffer> characterUniformBuffer;
@property (nonatomic, weak) id<MTLCommandQueue> commandQueue;

@property (nonatomic, strong) NuoMesh* lightVector;


@end



@implementation NotationLight


- (instancetype)initWithCommandQueue:(id<MTLCommandQueue>)commandQueue isBold:(BOOL)bold
{
    self = [super init];
    
    if (self)
    {
        _commandQueue = commandQueue;
        
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
        
        _lightVector = [[NuoMesh alloc] initWithCommandQueue:commandQueue
                                    withVerticesBuffer:arrow->Ptr() withLength:arrow->Length()
                                           withIndices:arrow->IndicesPtr() withLength:arrow->IndicesLength()];
        
        MTLRenderPipelineDescriptor* pipelineDesc = [_lightVector makePipelineStateDescriptor];
        
        // if no MSAA, shoud uncomment the floowing line
        // pipelineDesc.sampleCount = 1;
        
        [_lightVector setBoundingBoxLocal:meshBounding];
        [_lightVector makePipelineState:pipelineDesc];
        [_lightVector makeDepthStencilState];
    }
    
    return self;
}


- (NuoMeshBox*)boundingBox
{
    return _lightVector.boundingBoxLocal;
}


- (void)makeResources
{
    _characterUniformBuffer = [self.commandQueue.device newBufferWithLength:sizeof(NuoModelCharacterUniforms)
                                                                    options:MTLResourceStorageModePrivate];
    [self updatePrivateUniform];
}


- (void)updateUniformsForView:(unsigned int)inFlight
{
    NuoLightSource* desc = _lightSourceDesc;
    NuoMeshBox* bounding = _lightVector.boundingBoxLocal;
    
    const vector_float3 translationToCenter =
    {
        - bounding.center.x,
        - bounding.center.y,
        - bounding.center.z + bounding.span.z / 2.0f
    };
    
    const matrix_float4x4 modelCenteringMatrix = matrix_translation(translationToCenter);
    const matrix_float4x4 modelMatrix = matrix_rotation_append(modelCenteringMatrix, desc.lightingRotationX, desc.lightingRotationY);
    [_lightVector updateUniform:inFlight withTransform:modelMatrix];
    
    NuoModelCharacterUniforms characters;
    characters.opacity = _selected ? 1.0f : 0.1f;
}


- (void)updatePrivateUniform
{
    NuoModelCharacterUniforms uniforms;
    uniforms.opacity = _selected ? 1.0f : 0.1f;
    
    id<MTLBuffer> buffer = [self.commandQueue.device newBufferWithLength:sizeof(NuoModelCharacterUniforms)
                                                                 options:MTLResourceOptionCPUCacheModeDefault];
    memcpy([buffer contents], &uniforms, sizeof(NuoModelCharacterUniforms));
    
    id<MTLCommandBuffer> commandBuffer = [self.commandQueue commandBuffer];
    id<MTLBlitCommandEncoder> encoder = [commandBuffer blitCommandEncoder];
    
    [encoder copyFromBuffer:buffer sourceOffset:0
                   toBuffer:_characterUniformBuffer destinationOffset:0
                       size:sizeof(NuoModelCharacterUniforms)];
    
    [encoder endEncoding];
    [commandBuffer commit];
}


- (void)setSelected:(BOOL)selected
{
    BOOL changed = (_selected != selected);
    
    _selected = selected;
    
    if (changed)
        [self updatePrivateUniform];
    
    [_lightVector setTransparency:!_selected];
    [_lightVector makeDepthStencilState];
}


- (CGPoint)headPointProjected
{
    NuoLightSource* desc = _lightSourceDesc;
    
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
    [renderPass setFragmentBuffer:self.characterUniformBuffer offset:0 atIndex:1];
    
    // the light vector notation does not have varying uniform,
    // use only the 0th buffer
    //
    [_lightVector drawMesh:renderPass indexBuffer:inFlight];
}



@end
