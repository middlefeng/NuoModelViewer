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

#import "NotationLight.h"
#import "ModelUniforms.h"


@interface NotationRenderer()

@property (nonatomic, strong) id<MTLBuffer> lightBuffer;

@property (nonatomic, strong) NotationLight* lightVector;

@end



@implementation NotationRenderer


- (instancetype)initWithDevice:(id<MTLDevice>)device
{
    self = [super initWithDevice:device];
    
    if (self)
    {
        _lightVector = [[NotationLight alloc] initWithDevice:device];
        
        // the direction of light used to render the "light vector"
        
        LightingUniforms lightUniform;
        lightUniform.lightVector.x = 0.13;
        lightUniform.lightVector.y = 0.72;
        lightUniform.lightVector.z = 0.68;
        lightUniform.lightVector.w = 0.0;
        
        _lightBuffer = [self.device newBufferWithLength:sizeof(LightingUniforms)
                                                options:MTLResourceOptionCPUCacheModeDefault];
        
        memcpy([_lightBuffer contents], &lightUniform, sizeof(LightingUniforms));
    }
    
    return self;
}




- (void)updateUniformsForView
{
    NuoMeshBox* bounding = _lightVector.boundingBox;
    
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
    
    const CGSize drawableSize = self.renderTarget.drawableSize;
    const float aspect = drawableSize.width / drawableSize.height;
    const float near = -cameraDistance - modelSpan + 0.01;
    const float far = near + modelSpan * 2.0 + 0.02;
    const matrix_float4x4 projectionMatrix = matrix_float4x4_perspective(aspect, (2 * M_PI) / 30, near, far);
    
    _lightVector.viewMatrix = viewMatrix;
    _lightVector.projMatrix = projectionMatrix;
}


- (void)setRotateX:(float)rotateX
{
    _lightVector.rotateX = rotateX;
}



- (float)rotateX
{
    return _lightVector.rotateX;
}



- (void)setRotateY:(float)rotateY
{
    _lightVector.rotateY = rotateY;
}



- (float)rotateY
{
    return _lightVector.rotateY;
}



- (void)drawWithCommandBuffer:(id<MTLCommandBuffer>)commandBuffer
{
    self.renderTarget.clearColor = MTLClearColorMake(0.0, 0.95, 0.95, 1);
    
    [super drawWithCommandBuffer:commandBuffer];
    
    id<MTLRenderCommandEncoder> renderPass = self.lastRenderPass;
    self.lastRenderPass = nil;
    
    const float lightSettingAreaFactor = 0.28;
    const float lightDensitySliderHeight = 50;
    
    CGSize drawableSize = self.renderTarget.drawableSize;
    MTLViewport viewPort;
    viewPort.originX = drawableSize.width * (1 - lightSettingAreaFactor);
    viewPort.originY = drawableSize.height * (1 - lightSettingAreaFactor) - lightDensitySliderHeight;
    viewPort.width = drawableSize.width * lightSettingAreaFactor;
    viewPort.height = drawableSize.height * lightSettingAreaFactor;
    viewPort.znear = 0.0;
    viewPort.zfar = 1.0;
    [renderPass setViewport:viewPort];
    
    CGFloat factor = [[NSScreen mainScreen] backingScaleFactor];
    _notationArea = CGRectMake(viewPort.originX, viewPort.originY, viewPort.width, viewPort.height);
    _notationArea.origin.y = drawableSize.height - _notationArea.origin.y - _notationArea.size.height;
    _notationArea.origin.x /= factor;
    _notationArea.origin.y /= factor;
    _notationArea.size.width /= factor;
    _notationArea.size.height /= factor;
    
    [self updateUniformsForView];
    [renderPass setVertexBuffer:self.lightBuffer offset:0 atIndex:2];
    
    [_lightVector drawWithRenderPass:renderPass];
    [renderPass endEncoding];
}



- (void)drawablePresented
{
    [super drawablePresented];
    [_lightVector drawablePresented];
}


@end
