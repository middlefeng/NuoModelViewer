//
//  ShadowMapRenderer.m
//  ModelViewer
//
//  Created by middleware on 1/16/17.
//  Copyright © 2017 middleware. All rights reserved.
//

#import "ShadowMapRenderer.h"
#import "LightSource.h"

#import "NuoShadowMapTarget.h"

#include "NuoMeshCompound.h"
#include "NuoUniforms.h"
#include "NuoMathUtilities.h"



@interface ShadowMapRenderer()

@property (nonatomic, strong) NSArray<id<MTLBuffer>>* transUniformBuffers;

@end



@implementation ShadowMapRenderer
{
    matrix_float4x4 _lightCastMatrix;
}



- (instancetype)initWithDevice:(id<MTLDevice>)device withName:(NSString*)name
{
    self = [super init];
    
    if (self)
    {
        self.renderTarget = [[NuoShadowMapTarget alloc] init];
        self.renderTarget.device = device;
        self.device = device;
        
        ((NuoShadowMapTarget*)self.renderTarget).name = name;
        
        [self makeResources];
    }
    
    return self;
}


- (void)makeResources
{
    id<MTLBuffer> modelBuffers[kInFlightBufferCount];
    
    for (size_t i = 0; i < kInFlightBufferCount; ++i)
    {
        modelBuffers[i] = [self.device newBufferWithLength:sizeof(NuoUniforms)
                                                   options:MTLResourceOptionCPUCacheModeDefault];
    }
    
    _transUniformBuffers = [[NSArray alloc] initWithObjects:modelBuffers count:kInFlightBufferCount];
}


- (void)updateUniformsForView:(unsigned int)inFlight
{
    vector_float3 center = {0, 0, 0};
    vector_float4 lightAsEye = {0, 0, 1, 0};
    vector_float3 up = {0, 1, 0};
    
    LightSource* lightSource = _lightSource;
    const matrix_float4x4 lightAsEyeMatrix = matrix_rotate(lightSource.lightingRotationX,
                                                           lightSource.lightingRotationY);
    lightAsEye = matrix_multiply(lightAsEyeMatrix, lightAsEye);
    vector_float3 lightAsEye3 = {lightAsEye.x, lightAsEye.y, lightAsEye.z};
    const matrix_float4x4 viewMatrix = matrix_lookAt(lightAsEye3, center, up);
    
    CGSize drawableSize = self.renderTarget.drawableSize;
    float meshRadius = _mesh.maxSpan / 2.0;
    float aspectRatio = drawableSize.width / drawableSize.height;
    float viewPortHeight = meshRadius;
    float viewPortWidth = aspectRatio * viewPortHeight;
    const matrix_float4x4 projectionMatrix = matrix_orthor(-viewPortWidth, viewPortWidth,
                                                           viewPortHeight, -viewPortHeight,
                                                           -meshRadius, meshRadius);
    
    NuoUniforms uniforms;
    uniforms.viewMatrix = viewMatrix;
    uniforms.viewProjectionMatrix = matrix_multiply(projectionMatrix, uniforms.viewMatrix);
    
    _lightCastMatrix = uniforms.viewProjectionMatrix;
    
    memcpy([self.transUniformBuffers[inFlight] contents], &uniforms, sizeof(uniforms));
}


- (void)drawWithCommandBuffer:(id<MTLCommandBuffer>)commandBuffer withInFlightIndex:(unsigned int)inFlight
{
    MTLRenderPassDescriptor *passDescriptor = [self.renderTarget currentRenderPassDescriptor];
    if (!passDescriptor)
        return;
    
    [self updateUniformsForView:inFlight];
    
    id<MTLRenderCommandEncoder> renderPass = [commandBuffer renderCommandEncoderWithDescriptor:passDescriptor];

    [renderPass setVertexBuffer:self.transUniformBuffers[inFlight] offset:0 atIndex:1];
    [_mesh drawShadow:renderPass indexBuffer:inFlight];
    
    [renderPass endEncoding];
}


- (matrix_float4x4)lightCastMatrix
{
    return _lightCastMatrix;
}


@end
