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

#import "NuoMesh.h"
#import "NuoMeshBounds.h"

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
        self.renderTarget = [[NuoShadowMapTarget alloc] initWithCommandQueue:commandQueue
                                                             withPixelFormat:MTLPixelFormatBGRA8Unorm
                                                             withSampleCount:1];
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
    // use an arbitrary camera vector and an arbitrary rotation center for the light source
    // viewpoint since the light is directional (not position sensative)
    //
    // the shadow map range will be determined later by the post-view-transform bounds
    //
    const vector_float4 center = {0, 0, 0, 1};
    static const float kCameraDistance = 1.0;
    vector_float4 lightAsEye = {0, 0, kCameraDistance, 1};
    
    NuoLightSource* lightSource = _lightSource;
    const matrix_float4x4 lightAsEyeMatrix = matrix_rotate(lightSource.lightingRotationX,
                                                           lightSource.lightingRotationY);
    lightAsEye = matrix_multiply(lightAsEyeMatrix, lightAsEye);
    lightAsEye = lightAsEye + center;
    lightAsEye.w = 1.0;
    
    const vector_float3 up = {0, 1, 0};
    const matrix_float4x4 viewMatrix = matrix_lookAt(lightAsEye.xyz, center.xyz, up);
    
    CGSize drawableSize = self.renderTarget.drawableSize;
    float aspectRatio = drawableSize.width / drawableSize.height;
    
    NuoBounds bounds;
    if (_meshes && _meshes.count > 0)
    {
        bounds = *((NuoBounds*)[[_meshes[0] worldBounds:viewMatrix] boundingBox]);
        for (NSUInteger i = 1; i < _meshes.count; ++i)
            bounds = bounds.Union(*((NuoBounds*)[_meshes[i] worldBounds:viewMatrix].boundingBox));
    }
    
    float viewPortHeight = bounds._span.y / 2.0;
    float viewPortWidth = bounds._span.x / 2.0;
    
    // the shadow map is of the same aspect ratio (and resolution) as the scene render target,
    // which is not an optimal decision, yet has to be respected here
    //
    if (viewPortWidth / viewPortHeight < aspectRatio)
        viewPortWidth = aspectRatio * viewPortHeight;
    else
        viewPortHeight = viewPortWidth / aspectRatio;
    
    float l = bounds._center.x - viewPortWidth;
    float r = bounds._center.x + viewPortWidth;
    float t = bounds._center.y + viewPortHeight;
    float b = bounds._center.y - viewPortHeight;
    
    float near = -bounds._span.z / 2.0 - bounds._center.z;
    float far =   bounds._span.z / 2.0 - bounds._center.z;
    
    const matrix_float4x4 projectionMatrix = matrix_orthor(l, r, t, b, near, far);
    
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
