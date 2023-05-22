//
//  NuoShadowMapRenderer.m
//  ModelViewer
//
//  Created by middleware on 1/16/17.
//  Copyright © 2020 middleware. All rights reserved.
//

#import "NuoShadowMapRenderer.h"

#import "NuoCommandBuffer.h"
#import "NuoBufferSwapChain.h"
#import "NuoLightSource.h"
#import "NuoShadowMapTarget.h"

#import "NuoMeshSceneRoot.h"
#import "NuoMeshBounds.h"

#include "NuoUniforms.h"
#include "NuoTypes.h"
#include "NuoMathVector.h"



@interface NuoShadowMapRenderer()

@property (nonatomic, strong) NuoBufferSwapChain* transUniformBuffers;

@end



@implementation NuoShadowMapRenderer
{
    NuoMatrixFloat44 _lightCastMatrix;
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
    _transUniformBuffers = [[NuoBufferSwapChain alloc] initWithDevice:self.commandQueue.device
                                                       WithBufferSize:sizeof(NuoUniforms)
                                                          withOptions:MTLResourceStorageModeManaged
                                                        withChainSize:kInFlightBufferCount];
}


- (void)updateUniformsForView:(id<NuoRenderInFlight>)inFlight
{
    // use an arbitrary camera vector and an arbitrary rotation center for the light source
    // viewpoint since the light is directional (not position sensitive)
    //
    // the light source viewpoint volume will be determined later by the post-view-transform bounds
    //
    const NuoVectorFloat4 center(0, 0, 0, 1);
    static const float kCameraDistance = 1.0;
    NuoVectorFloat4 lightAsEye(0, 0, kCameraDistance, 1);
    
    lightAsEye = _lightSource.lightDirection * lightAsEye;
    lightAsEye = lightAsEye + center;
    lightAsEye.w(1.0);
    
    const NuoVectorFloat3 up(0, 1, 0);
    const NuoMatrixFloat44 viewMatrix = NuoMatrixLookAt(NuoVectorFloat3(lightAsEye.x(), lightAsEye.y(), lightAsEye.z()),
                                                        NuoVectorFloat3(center.x(), center.y(), center.z()), up);
    
    CGSize drawableSize = self.renderTarget.drawableSize;
    float aspectRatio = drawableSize.width / drawableSize.height;
    
    NuoBounds bounds;
    if (_sceneRoot && _sceneRoot.meshes.count > 0)
        bounds = [_sceneRoot worldBounds:viewMatrix].boundingBox;
    
    float viewPortHeight = bounds._span.y() / 2.0f;
    float viewPortWidth = bounds._span.x() / 2.0f;
    
    // the shadow map is of the same aspect ratio (and resolution) as the scene render target,
    // which is not an optimal decision, yet has to be respected here
    //
    if (viewPortWidth / viewPortHeight < aspectRatio)
        viewPortWidth = aspectRatio * viewPortHeight;
    else
        viewPortHeight = viewPortWidth / aspectRatio;
    
    float l = bounds._center.x() - viewPortWidth;
    float r = bounds._center.x() + viewPortWidth;
    float t = bounds._center.y() + viewPortHeight;
    float b = bounds._center.y() - viewPortHeight;
    
    float near = -bounds._span.z() / 2.0 - bounds._center.z();
    float far =   bounds._span.z() / 2.0 - bounds._center.z();
    
    const NuoMatrixFloat44 projectionMatrix = NuoMatrixOrthor(l, r, t, b, near, far);
    
    NuoUniforms uniforms;
    uniforms.viewMatrix = viewMatrix._m;
    uniforms.viewProjectionMatrix = (projectionMatrix * viewMatrix)._m;
    
    _lightCastMatrix = uniforms.viewProjectionMatrix;
    
    [_transUniformBuffers updateBufferWithInFlight:inFlight withContent:&uniforms];
}


- (void)drawWithCommandBuffer:(NuoCommandBuffer*)commandBuffer
{
    [self updateUniformsForView:commandBuffer];
    
    NuoRenderPassEncoder* renderPass = [self retainDefaultEncoder:commandBuffer];
    if (!renderPass)
        return;
    
    renderPass.label = @"Shadow Map";

    [renderPass setVertexBufferInFlight:_transUniformBuffers offset:0 atIndex:1];
    [_sceneRoot drawShadow:renderPass];
    
    [self releaseDefaultEncoder];
}



- (const NuoMatrixFloat44&)lightCastMatrix
{
    return _lightCastMatrix;
}


@end
