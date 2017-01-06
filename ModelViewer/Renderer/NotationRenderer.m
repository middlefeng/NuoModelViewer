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
#import "ModelUniforms.h"
#import "LightSource.h"

#import <math.h>


@interface NotationRenderer()

@property (nonatomic, strong) id<MTLBuffer> lightBuffer;

@property (nonatomic, strong) NSArray<NotationLight*>* lightVectors;
@property (nonatomic, weak) NotationLight* currentLightVector;

@end



@implementation NotationRenderer


- (instancetype)initWithDevice:(id<MTLDevice>)device
{
    self = [super initWithDevice:device];
    
    if (self)
    {
        NSMutableArray* lightVectors = [[NSMutableArray alloc] init];
        
        for (unsigned int index = 0; index < 4; ++index)
        {
            NotationLight* lightNotation = [[NotationLight alloc] initWithDevice:device];
            [lightVectors addObject:lightNotation];
        }
        _lightVectors = lightVectors;
        _currentLightVector = lightVectors[0];
        
        // the direction of light used to render the "light vector"
        
        LightingUniforms lightUniform;
        lightUniform.lightVector[0].x = 0.13;
        lightUniform.lightVector[0].y = 0.72;
        lightUniform.lightVector[0].z = 0.68;
        lightUniform.lightVector[0].w = 0.0;
        
        lightUniform.lightDensity[0] = 1.0f;
        lightUniform.lightDensity[1] = 0.0f;
        lightUniform.lightDensity[2] = 0.0f;
        lightUniform.lightDensity[3] = 0.0f;
        
        _lightBuffer = [self.device newBufferWithLength:sizeof(LightingUniforms)
                                                options:MTLResourceOptionCPUCacheModeDefault];
        
        memcpy([_lightBuffer contents], &lightUniform, sizeof(LightingUniforms));
    }
    
    return self;
}




- (void)updateUniformsForView
{
    NuoMeshBox* bounding = _lightVectors[0].boundingBox;
    
    float zoom = -200.0;
    
    float modelSpan = fmax(bounding.spanZ, bounding.spanX);
    modelSpan = fmax(bounding.spanY, modelSpan);
    
    const float modelNearest = - modelSpan;
    const float cameraDefaultDistance = (modelNearest - modelSpan);
    const float cameraDistance = cameraDefaultDistance + zoom * modelSpan / 20.0f;
    
    const vector_float3 cameraTranslation =
    {
        0, 0, cameraDistance
    };
    
    const matrix_float4x4 viewMatrix = matrix_float4x4_translation(cameraTranslation);
    
    const float aspect = _notationArea.size.width / _notationArea.size.height;
    const float near = -cameraDistance - modelSpan;
    const float far = near + modelSpan * 2.0;
    const matrix_float4x4 projectionMatrix = matrix_float4x4_perspective(aspect, (2 * M_PI) / 30, near, far);
    
    for (size_t i = 0; i < _lightVectors.count; ++i)
    {
        _lightVectors[i].viewMatrix = viewMatrix;
        _lightVectors[i].projMatrix = projectionMatrix;
    }
}


- (NSArray<LightSource*>*)lightSources
{
    LightSource* result[4];
    
    for (unsigned int i = 0; i < 4; ++i)
    {
        result[i] = [LightSource new];
        result[i].lightingRotationX = _lightVectors[i].rotateX;
        result[i].lightingRotationY = _lightVectors[i].rotateY;
        result[i].lightingDensity = _lightVectors[i].density;
        result[i].lightingSpacular = _lightVectors[i].spacular;
    }
    
    return [[NSArray alloc] initWithObjects:result[0], result[1], result[2], result[3], nil];
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
        _lightVectors[lightIndex].rotateX = [lua getFieldAsNumber:@"rotateX" fromTable:-1];
        _lightVectors[lightIndex].rotateY = [lua getFieldAsNumber:@"rotateY" fromTable:-1];
        _lightVectors[lightIndex].density = [lua getFieldAsNumber:@"density" fromTable:-1];
        _lightVectors[lightIndex].spacular = [lua getFieldAsNumber:@"spacular" fromTable:-1];
        [lua removeField];
    }
    [lua removeField];
}



- (void)setDensity:(float)density
{
    _currentLightVector.density = density;
}


- (float)density
{
    return _currentLightVector.density;
}


- (void)setSpacular:(float)spacular
{
    _currentLightVector.spacular = spacular;
}


- (float)spacular
{
    return _currentLightVector.spacular;
}


- (void)setRotateX:(float)rotateX
{
    _currentLightVector.rotateX = rotateX;
}



- (float)rotateX
{
    return _currentLightVector.rotateX;
}


- (void)setRotateY:(float)rotateY
{
    _currentLightVector.rotateY = rotateY;
}



- (float)rotateY
{
    return _currentLightVector.rotateY;
}



- (void)drawWithCommandBuffer:(id<MTLCommandBuffer>)commandBuffer
{
    self.renderTarget.clearColor = MTLClearColorMake(0.0, 0.95, 0.95, 1);
    
    [super drawWithCommandBuffer:commandBuffer];
    
    id<MTLRenderCommandEncoder> renderPass = self.lastRenderPass;
    self.lastRenderPass = nil;
    
    const float lightSettingAreaFactor = 0.28;
    const float lightDensitySliderHeight = 100;
    const CGFloat factor = [[NSScreen mainScreen] backingScaleFactor];
    
    CGSize drawableSize = self.renderTarget.drawableSize;
    MTLViewport viewPort;
    viewPort.width = fmin(drawableSize.width * lightSettingAreaFactor, _notationWidthCap * factor);
    viewPort.height = fmin(drawableSize.height * lightSettingAreaFactor, _notationWidthCap * factor);
    viewPort.originX = drawableSize.width - viewPort.width;
    viewPort.originY = drawableSize.height - viewPort.height - lightDensitySliderHeight;
    viewPort.znear = 0.0;
    viewPort.zfar = 1.0;
    [renderPass setViewport:viewPort];
    
    _notationArea = CGRectMake(viewPort.originX, viewPort.originY, viewPort.width, viewPort.height);
    _notationArea.origin.y = drawableSize.height - _notationArea.origin.y - _notationArea.size.height;
    _notationArea.origin.x /= factor;
    _notationArea.origin.y /= factor;
    _notationArea.size.width /= factor;
    _notationArea.size.height /= factor;
    
    [self updateUniformsForView];
    
    [renderPass setCullMode:MTLCullModeNone];
    [renderPass setFragmentBuffer:self.lightBuffer offset:0 atIndex:0];
    
    for (size_t i = 0; i < _lightVectors.count; ++i)
    {
        [_lightVectors[i] drawWithRenderPass:renderPass];
    }
    
    [renderPass endEncoding];
}



- (void)drawablePresented
{
    [super drawablePresented];
    
    for (size_t i = 0; i < _lightVectors.count; ++i)
        [_lightVectors[i] drawablePresented];
}


@end
