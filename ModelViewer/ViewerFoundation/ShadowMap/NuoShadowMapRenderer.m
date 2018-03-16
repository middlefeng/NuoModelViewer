//
//  NuoShadowMapRenderer.m
//  ModelViewer
//
//  Created by middleware on 1/16/17.
//  Copyright © 2017 middleware. All rights reserved.
//

#import "NuoShadowMapRenderer.h"

#import "NuoLightSource.h"
#import "NuoShadowMapTarget.h"

#include "NuoMesh.h"
#include "NuoUniforms.h"
#include "NuoMathUtilities.h"



@interface NuoShadowMapRenderer()

@property (nonatomic, strong) NSArray<id<MTLBuffer>>* transUniformBuffers;

@end



@implementation NuoShadowMapRenderer
{
    matrix_float4x4 _lightCastMatrix;
}



- (instancetype)initWithCommandQueue:(id<MTLCommandQueue>)commandQueue withName:(NSString *)name
{
    self = [super init];
    
    if (self)
    {
        self.renderTarget = [[NuoShadowMapTarget alloc] initWithCommandQueue:commandQueue withSampleCount:1];
        self.commandQueue = commandQueue;
        
        ((NuoShadowMapTarget*)self.renderTarget).name = name;
        
        [self makeResources];
    }
    
    return self;
}


- (void)makeResources
{
    id<MTLBuffer> transBuffers[kInFlightBufferCount];
    
    for (size_t i = 0; i < kInFlightBufferCount; ++i)
    {
        transBuffers[i] = [self.commandQueue.device newBufferWithLength:sizeof(NuoUniforms)
                                                                options:MTLResourceOptionCPUCacheModeDefault];
    }
    
    _transUniformBuffers = [[NSArray alloc] initWithObjects:transBuffers count:kInFlightBufferCount];
}


- (void)updateUniformsForView:(unsigned int)inFlight
{
    static const float kCameraDistance = 1.0;
    
    vector_float4 center = {0, 0, 0, 1};
    float meshRadius = 0.0;
    
    NuoBoundingSphere* sphere = nil;
    if (_meshes && _meshes.count > 0)
    {
        sphere = [_meshes[0] boundingSphere];
        for (NSUInteger i = 1; i < _meshes.count; ++i)
            sphere = [sphere unionWith:[_meshes[i] boundingSphere]];
        
        center.x = sphere.center.x;
        center.y = sphere.center.y;
        center.z = sphere.center.z;
        meshRadius = sphere.radius;
    }
    
    vector_float4 lightAsEye = {0, 0, kCameraDistance, 1};
    vector_float3 up = {0, 1, 0};
    
    NuoLightSource* lightSource = _lightSource;
    const matrix_float4x4 lightAsEyeMatrix = matrix_rotate(lightSource.lightingRotationX,
                                                           lightSource.lightingRotationY);
    lightAsEye = matrix_multiply(lightAsEyeMatrix, lightAsEye);
    lightAsEye = lightAsEye + center;
    
    const matrix_float4x4 viewMatrix = matrix_lookAt(lightAsEye.xyz, center.xyz, up);
    
    CGSize drawableSize = self.renderTarget.drawableSize;
    float aspectRatio = drawableSize.width / drawableSize.height;
    float viewPortHeight = meshRadius;
    float viewPortWidth = aspectRatio * viewPortHeight;
    const matrix_float4x4 projectionMatrix = matrix_orthor(-viewPortWidth, viewPortWidth,
                                                           viewPortHeight, -viewPortHeight,
                                                           -meshRadius + kCameraDistance, meshRadius + kCameraDistance);
    
    NuoUniforms uniforms;
    uniforms.viewMatrix = viewMatrix;
    uniforms.viewProjectionMatrix = matrix_multiply(projectionMatrix, uniforms.viewMatrix);
    
    _lightCastMatrix = uniforms.viewProjectionMatrix;
    
    memcpy([self.transUniformBuffers[inFlight] contents], &uniforms, sizeof(uniforms));
}


- (void)drawWithCommandBuffer:(id<MTLCommandBuffer>)commandBuffer withInFlightIndex:(unsigned int)inFlight
{
    [self updateUniformsForView:inFlight];
    
    id<MTLRenderCommandEncoder> renderPass = [self retainDefaultEncoder:commandBuffer];
    if (!renderPass)
        return;
    
    renderPass.label = @"Shadow Map";

    [renderPass setVertexBuffer:self.transUniformBuffers[inFlight] offset:0 atIndex:1];
    for (NuoMesh* mesh in _meshes)
    {
        if (mesh.enabled)
            [mesh drawShadow:renderPass indexBuffer:inFlight];
    }
    
    [self releaseDefaultEncoder];
}



- (matrix_float4x4)lightCastMatrix
{
    return _lightCastMatrix;
}


@end
