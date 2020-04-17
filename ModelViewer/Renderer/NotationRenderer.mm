//
//  NotationRenderer.m
//  ModelViewer
//
//  Created by dfeng on 11/8/16.
//  Copyright © 2020 middleware. All rights reserved.
//


#import "NotationRenderer.h"

#import "NuoMesh.h"
#import "NuoLua.h"

#import "NotationLight.h"
#import "NuoUniforms.h"
#import "NuoLightSource.h"

#import <math.h>
#import <AppKit/AppKit.h>

#import "NuoMeshBounds.h"
#import "NuoCommandBuffer.h"
#import "NuoBufferSwapChain.h"

#import "ModelState.h"
#include "NuoTypes.h"


@interface NotationRenderer()

// light to illuminate the notations
//
@property (nonatomic, strong) id<MTLBuffer> lightBuffer;

@property (nonatomic, strong) NuoBufferSwapChain* transforms;

@property (nonatomic, strong) NSArray<NotationLight*>* lightVectors;
@property (nonatomic, weak) NotationLight* currentLightVector;

@end



@implementation NotationRenderer


- (instancetype)initWithCommandQueue:(id<MTLCommandQueue>)commandQueue
{
    self = [super initWithCommandQueue:commandQueue
                       withPixelFormat:MTLPixelFormatBGRA8Unorm
                       withSampleCount:kSampleCount];
    
    if (self)
    {
        NSMutableArray* lightVectors = [[NSMutableArray alloc] init];
        NSMutableArray<NuoLightSource*>* lightSourcesDesc = [[NSMutableArray alloc] init];
        
        for (unsigned int index = 0; index < 4; ++index)
        {
            NotationLight* lightNotation = [[NotationLight alloc] initWithCommandQueue:commandQueue
                                                                                isBold:index < 2 /* the first two with shadow casting */];
            [lightVectors addObject:lightNotation];
            
            NuoLightSource* lightSource = [[NuoLightSource alloc] init];
            lightSource.enableShadow = (index < 2);
            
            lightNotation.lightSourceDesc = lightSource;
            [lightSourcesDesc addObject:lightSource];
        }
        _lightVectors = lightVectors;
        _lightSources = lightSourcesDesc;
        
        _currentLightVector = lightVectors[0];
        _currentLightVector.selected = YES;
        
        lightSourcesDesc[0].lightingIrradiance = 1.0f;
        lightSourcesDesc[0].lightingSpecular = 0.4f;
        lightSourcesDesc[0].shadowOccluderRadius = 5.0f;
        
        // the direction of light used to render the "light vector"
        //
        NuoLightUniforms lightUniform; memset(&lightUniform, 0, sizeof(NuoLightUniforms));
        
        lightUniform.lightParams[0].direction.x = 0.13;
        lightUniform.lightParams[0].direction.y = 0.72;
        lightUniform.lightParams[0].direction.z = 0.68;
        lightUniform.lightParams[0].irradiance = 1.0f;
        lightUniform.lightParams[0].specular = 0.6f;
        
        _lightBuffer = [commandQueue.device newBufferWithLength:sizeof(NuoLightUniforms)
                                                        options:MTLResourceOptionCPUCacheModeDefault];
        
        memcpy([_lightBuffer contents], &lightUniform, sizeof(NuoLightUniforms));
        
        _transforms = [[NuoBufferSwapChain alloc] initWithDevice:commandQueue.device
                                                  WithBufferSize:sizeof(NuoUniforms)
                                                     withOptions:MTLResourceStorageModeManaged
                                                   withChainSize:kInFlightBufferCount];
    }
    
    return self;
}




- (void)updateUniformsForView:(id<NuoRenderInFlight>)inFlight
{
    const NuoMeshBounds meshBounds = _lightVectors[0].bounds;
    const NuoBounds& bounds = meshBounds.boundingBox;
    const float modelSpan = bounds.MaxDimension();
    
    const float zoom = -200.0;
    
    const float modelNearest = - modelSpan;
    const float cameraDefaultDistance = (modelNearest - modelSpan);
    const float cameraDistance = cameraDefaultDistance + zoom * modelSpan / 20.0f;
    
    const NuoVectorFloat3 cameraTranslation(0, 0, cameraDistance);
    const NuoMatrixFloat44 viewMatrix = NuoMatrixTranslation(cameraTranslation) * _modelState.viewRotationMatrix;
    
    const float aspect = _notationArea.size.width / _notationArea.size.height;
    const float near = -cameraDistance - modelSpan;
    const float far = near + modelSpan * 2.0;
    const NuoMatrixFloat44 projectionMatrix = NuoMatrixPerspective(aspect, (2 * M_PI) / 30, near, far);
    
    NuoUniforms uniforms;
    uniforms.viewMatrix = viewMatrix._m;
    uniforms.viewMatrixInverse = viewMatrix.Inverse()._m;
    uniforms.viewProjectionMatrix = (projectionMatrix * viewMatrix)._m;
    
    [_transforms updateBufferWithInFlight:inFlight withContent:&uniforms];
}


- (void)selectCurrentLightVector:(CGPoint)point
{
    const CGPoint normalized =
    {
        .x = (point.x - _notationArea.origin.x) / _notationArea.size.width * 2.0 - 1.0,
        .y = (point.y - _notationArea.origin.y) / _notationArea.size.height * 2.0 - 1.0
    };
    
    float minDistance = 2.0f;
    NotationLight* deselected = _currentLightVector;
    
    for (size_t i = 0; i < _lightVectors.count; ++i)
    {
        CGPoint headProjected = [_lightVectors[i] headPointProjectedWithView:_modelState.viewRotationMatrix];
        float distance = sqrt((headProjected.x - normalized.x) * (headProjected.x - normalized.x) +
                              (headProjected.y - normalized.y) * (headProjected.y - normalized.y));
        if (distance < minDistance)
        {
            minDistance = distance;
            _currentLightVector = _lightVectors[i];
        }
    }
    
    if (deselected != _currentLightVector)
    {
        _currentLightVector.selected = YES;
        deselected.selected = NO;
    }
}


- (void)importScene:(NuoLua*)lua
{
    lua->GetField("lights", -1);
    for (int lightIndex = 0; lightIndex < _lightVectors.count; ++lightIndex)
    {
        lua->GetItem(lightIndex, -1);
        
        float rotationX = 0;
        float rotationY = 0;
        
        lua->GetField("rotateX", -1);
        if (!lua->IsNil(-1))
            rotationX = lua->GetFieldAsNumber("rotateX", -2);
        lua->RemoveField();
        
        lua->GetField("rotateY", -1);
        if (!lua->IsNil(-1))
            rotationY = lua->GetFieldAsNumber("rotateY", -2);
        lua->RemoveField();
        
        if (rotationX != 0 || rotationY != 0)
            _lightSources[lightIndex].lightDirection = NuoMatrixRotation(rotationX, rotationY);
        
        lua->GetField("rotation", -1);
        if (!lua->IsNil(-1))
            _lightSources[lightIndex].lightDirection = lua->GetMatrixFromTable(-1);
        lua->RemoveField();
        
        _lightSources[lightIndex].lightingIrradiance = lua->GetFieldAsNumber("irradiance", -1);
        _lightSources[lightIndex].lightingSpecular = lua->GetFieldAsNumber("specular", -1);
        _lightSources[lightIndex].enableShadow = lua->GetFieldAsBool("enableShadow", -1);
        
        if (_lightSources[lightIndex].enableShadow)
        {
            assert(lightIndex < 2);
            
            _lightSources[lightIndex].shadowSoften = lua->GetFieldAsNumber("shadowSoften", -1);
            _lightSources[lightIndex].shadowBias = lua->GetFieldAsNumber("shadowBias", -1);
        }
        else
        {
            assert(lightIndex >= 2);
        }
        
        lua->RemoveField();
    }
    lua->RemoveField();
}


- (NuoLightSource*)selectedLightSource
{
    return _currentLightVector.lightSourceDesc;
}


- (void)setIrradiance:(float)irradiance
{
    _currentLightVector.lightSourceDesc.lightingIrradiance = irradiance;
}


- (void)setSpecular:(float)specular
{
    if (_physicallySpecular)
    {
        // physically based specular need not per-light adjust factor
        //
        for (NotationLight* light : _lightVectors)
            light.lightSourceDesc.lightingSpecular = specular;
    }
    else
    {
        _currentLightVector.lightSourceDesc.lightingSpecular = specular;
    }
}


- (void)updateRotationX:(float)deltaX Y:(float)deltaY
{
    const NuoMatrixFloat44 updateMatrix = NuoMatrixRotation(deltaX, deltaY);
    const NuoMatrixFloat44 viewRotation = _modelState.viewRotationMatrix;
    _currentLightVector.lightSourceDesc.lightDirection
            = (viewRotation.Inverse() * updateMatrix * viewRotation)
                        * _currentLightVector.lightSourceDesc.lightDirection;
}


- (void)setShadowSoften:(float)soften
{
    _currentLightVector.lightSourceDesc.shadowSoften = soften;
}


- (void)setShadowOccluderRadius:(float)shadowOccluder
{
    _currentLightVector.lightSourceDesc.shadowOccluderRadius = shadowOccluder;
}


- (void)setShadowBias:(float)bias
{
    _currentLightVector.lightSourceDesc.shadowBias = bias;
}


- (void)drawWithCommandBuffer:(NuoCommandBuffer*)commandBuffer
{
    self.renderTarget.clearColor = MTLClearColorMake(0.0, 0.95, 0.95, 1);
    
    NuoRenderPassEncoder* renderPass = [self retainDefaultEncoder:commandBuffer];
    
    [super drawWithCommandBuffer:commandBuffer];
    
    const float lightSettingAreaFactor = 0.28;
    const float lightSlidersHeight = 140;
    const CGFloat factor = [[NSScreen mainScreen] backingScaleFactor];
    
    CGSize drawableSize = self.renderTarget.drawableSize;
    MTLViewport viewPort;
    viewPort.width = fmin(drawableSize.width * lightSettingAreaFactor, _notationWidthCap * factor);
    viewPort.height = fmin(drawableSize.height * lightSettingAreaFactor, _notationWidthCap * factor);
    viewPort.originX = drawableSize.width - viewPort.width;
    viewPort.originY = drawableSize.height - viewPort.height + 60 - lightSlidersHeight * factor;
    viewPort.znear = 0.0;
    viewPort.zfar = 1.0;
    [renderPass setViewport:viewPort];
    
    _notationArea = CGRectMake(viewPort.originX, viewPort.originY, viewPort.width, viewPort.height);
    _notationArea.origin.y = drawableSize.height - _notationArea.origin.y - _notationArea.size.height;
    _notationArea.origin.x /= factor;
    _notationArea.origin.y /= factor;
    _notationArea.size.width /= factor;
    _notationArea.size.height /= factor;
    
    [self updateUniformsForView:commandBuffer];
    
    [renderPass setCullMode:MTLCullModeNone];
    [renderPass setVertexBufferSwapChain:_transforms offset:0 atIndex:1];
    [renderPass setFragmentBuffer:_lightBuffer offset:0 atIndex:0];
    
    for (size_t i = 0; i < _lightVectors.count; ++i)
    {
        [_lightVectors[i] drawWithRenderPass:renderPass];
    }
    
    [self releaseDefaultEncoder];
}



@end
