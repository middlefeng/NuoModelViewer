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
#import "NuoLua.h"

#import "NotationLight.h"
#import "NuoUniforms.h"
#import "NuoLightSource.h"

#import <math.h>


@interface NotationRenderer()

// light to illuminate the notations
//
@property (nonatomic, strong) id<MTLBuffer> lightBuffer;

@property (nonatomic, strong) NSArray<id<MTLBuffer>>* transforms;

@property (nonatomic, strong) NSArray<NotationLight*>* lightVectors;
@property (nonatomic, weak) NotationLight* currentLightVector;

@end



@implementation NotationRenderer


- (instancetype)initWithDevice:(id<MTLDevice>)device
{
    self = [super initWithDevice:device withPixelFormat:MTLPixelFormatBGRA8Unorm];
    
    if (self)
    {
        NSMutableArray* lightVectors = [[NSMutableArray alloc] init];
        NSMutableArray<NuoLightSource*>* lightSourcesDesc = [[NSMutableArray alloc] init];
        
        for (unsigned int index = 0; index < 4; ++index)
        {
            NotationLight* lightNotation = [[NotationLight alloc] initWithDevice:device
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
        lightSourcesDesc[0].lightingDensity = 1.0f;
        lightSourcesDesc[0].lightingSpacular = 0.4f;
        
        // the direction of light used to render the "light vector"
        //
        LightUniform lightUniform; memset(&lightUniform, 0, sizeof(LightUniform));
        
        lightUniform.direction[0].x = 0.13;
        lightUniform.direction[0].y = 0.72;
        lightUniform.direction[0].z = 0.68;
        lightUniform.density[0] = 1.0f;
        lightUniform.spacular[0] = 0.6f;
        
        _lightBuffer = [self.device newBufferWithLength:sizeof(LightUniform)
                                                options:MTLResourceOptionCPUCacheModeDefault];
        
        memcpy([_lightBuffer contents], &lightUniform, sizeof(LightUniform));
        
        id<MTLBuffer> transformBuffer[kInFlightBufferCount];
        for (unsigned int i = 0; i < kInFlightBufferCount; ++i)
            transformBuffer[i] = [device newBufferWithLength:sizeof(NuoUniforms) options:MTLResourceOptionCPUCacheModeDefault];
        
        _transforms = [[NSArray alloc] initWithObjects:transformBuffer count:kInFlightBufferCount];
    }
    
    return self;
}




- (void)updateUniformsForView:(unsigned int)inFlight
{
    NuoMeshBox* bounding = _lightVectors[0].boundingBox;
    
    float zoom = -200.0;
    
    float modelSpan = [bounding.span maxDimension];
    
    const float modelNearest = - modelSpan;
    const float cameraDefaultDistance = (modelNearest - modelSpan);
    const float cameraDistance = cameraDefaultDistance + zoom * modelSpan / 20.0f;
    
    const vector_float3 cameraTranslation =
    {
        0, 0, cameraDistance
    };
    
    const matrix_float4x4 viewMatrix = matrix_translation(cameraTranslation);
    
    const float aspect = _notationArea.size.width / _notationArea.size.height;
    const float near = -cameraDistance - modelSpan;
    const float far = near + modelSpan * 2.0;
    const matrix_float4x4 projectionMatrix = matrix_perspective(aspect, (2 * M_PI) / 30, near, far);
    
    NuoUniforms uniforms;
    uniforms.viewMatrix = viewMatrix;
    uniforms.viewProjectionMatrix = matrix_multiply(projectionMatrix, uniforms.viewMatrix);
    
    memcpy([_transforms[inFlight] contents], &uniforms, sizeof(NuoUniforms));
}


- (void)selectCurrentLightVector:(CGPoint)point
{
    CGPoint normalized;
    normalized.x = (point.x - _notationArea.origin.x) / _notationArea.size.width * 2.0 - 1.0;
    normalized.y = (point.y - _notationArea.origin.y) / _notationArea.size.height * 2.0 - 1.0;
    
    float minDistance = 2.0f;
    
    for (size_t i = 0; i < _lightVectors.count; ++i)
    {
        _lightVectors[i].selected = NO;
        
        CGPoint headProjected = _lightVectors[i].headPointProjected;
        float distance = sqrt((headProjected.x - normalized.x) * (headProjected.x - normalized.x) +
                              (headProjected.y - normalized.y) * (headProjected.y - normalized.y));
        if (distance < minDistance)
        {
            minDistance = distance;
            _currentLightVector = _lightVectors[i];
        }
    }
    
    _currentLightVector.selected = YES;
}


- (void)importScene:(NuoLua*)lua
{
    [lua getField:@"lights" fromTable:-1];
    for (int lightIndex = 0; lightIndex < _lightVectors.count; ++lightIndex)
    {
        [lua getItem:lightIndex fromTable:-1];
        
        _lightSources[lightIndex].lightingRotationX = [lua getFieldAsNumber:@"rotateX" fromTable:-1];
        _lightSources[lightIndex].lightingRotationY = [lua getFieldAsNumber:@"rotateY" fromTable:-1];
        _lightSources[lightIndex].lightingDensity = [lua getFieldAsNumber:@"density" fromTable:-1];
        _lightSources[lightIndex].lightingSpacular = [lua getFieldAsNumber:@"spacular" fromTable:-1];
        _lightSources[lightIndex].enableShadow = [lua getFieldAsBool:@"enableShadow" fromTable:-1];
        
        if (_lightSources[lightIndex].enableShadow)
        {
            assert(lightIndex < 2);
            
            _lightSources[lightIndex].shadowSoften = [lua getFieldAsNumber:@"shadowSoften" fromTable:-1];
            _lightSources[lightIndex].shadowBias = [lua getFieldAsNumber:@"shadowBias" fromTable:-1];
        }
        else
        {
            assert(lightIndex >= 2);
        }
        
        [lua removeField];
    }
    [lua removeField];
}


- (NuoLightSource*)selectedLightSource
{
    return _currentLightVector.lightSourceDesc;
}


- (void)setDensity:(float)density
{
    _currentLightVector.lightSourceDesc.lightingDensity = density;
}


- (void)setSpacular:(float)spacular
{
    _currentLightVector.lightSourceDesc.lightingSpacular = spacular;
}


- (void)setRotateX:(float)rotateX
{
    _currentLightVector.lightSourceDesc.lightingRotationX = rotateX;
}



- (void)setRotateY:(float)rotateY
{
    _currentLightVector.lightSourceDesc.lightingRotationY = rotateY;
}


- (void)setShadowSoften:(float)soften
{
    _currentLightVector.lightSourceDesc.shadowSoften = soften;
}


- (void)setShadowBias:(float)bias
{
    _currentLightVector.lightSourceDesc.shadowBias = bias;
}


- (void)drawWithCommandBuffer:(id<MTLCommandBuffer>)commandBuffer
            withInFlightIndex:(unsigned int)inFlight
{
    self.renderTarget.clearColor = MTLClearColorMake(0.0, 0.95, 0.95, 1);
    
    [super drawWithCommandBuffer:commandBuffer withInFlightIndex:inFlight];
    
    id<MTLRenderCommandEncoder> renderPass = self.lastRenderPass;
    self.lastRenderPass = nil;
    
    const float lightSettingAreaFactor = 0.28;
    const float lightSlidersHeight = 140;
    const CGFloat factor = [[NSScreen mainScreen] backingScaleFactor];
    
    CGSize drawableSize = self.renderTarget.drawableSize;
    MTLViewport viewPort;
    viewPort.width = fmin(drawableSize.width * lightSettingAreaFactor, _notationWidthCap * factor);
    viewPort.height = fmin(drawableSize.height * lightSettingAreaFactor, _notationWidthCap * factor);
    viewPort.originX = drawableSize.width - viewPort.width;
    viewPort.originY = drawableSize.height - viewPort.height - lightSlidersHeight * factor;
    viewPort.znear = 0.0;
    viewPort.zfar = 1.0;
    [renderPass setViewport:viewPort];
    
    _notationArea = CGRectMake(viewPort.originX, viewPort.originY, viewPort.width, viewPort.height);
    _notationArea.origin.y = drawableSize.height - _notationArea.origin.y - _notationArea.size.height;
    _notationArea.origin.x /= factor;
    _notationArea.origin.y /= factor;
    _notationArea.size.width /= factor;
    _notationArea.size.height /= factor;
    
    [self updateUniformsForView:inFlight];
    
    [renderPass setCullMode:MTLCullModeNone];
    [renderPass setVertexBuffer:self.transforms[inFlight] offset:0 atIndex:1];
    [renderPass setFragmentBuffer:self.lightBuffer offset:0 atIndex:0];
    
    for (size_t i = 0; i < _lightVectors.count; ++i)
    {
        [_lightVectors[i] drawWithRenderPass:renderPass withInFlight:inFlight];
    }
    
    [renderPass endEncoding];
}



@end
