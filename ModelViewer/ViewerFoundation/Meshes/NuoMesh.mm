
#import "NuoMesh.h"

#include "tiny_obj_loader.h"

#include "NuoModelBase.h"
#include "NuoTypes.h"
#include "NuoMaterial.h"

#import <Cocoa/Cocoa.h>
#import "NuoMeshTextured.h"
#import "NuoMeshTexMatieraled.h"
#import "NuoMeshUniform.h"
#import "NuoMathUtilities.h"



const BOOL kShadowPCSS = YES;
const BOOL kShadowPCF = YES;



@interface NuoCoord ()


@property (assign, nonatomic) vector_float3 coord;


@end



@implementation NuoCoord


- (void)setX:(float)x
{
    _coord.x = x;
}



- (float)x
{
    return _coord.x;
}


- (void)setY:(float)y
{
    _coord.y = y;
}



- (float)y
{
    return _coord.y;
}


- (void)setZ:(float)z
{
    _coord.z = z;
}



- (float)z
{
    return _coord.z;
}


- (float)maxDimension
{
    float max = std::max(_coord.x, _coord.y);
    return std::max(max, _coord.z);
}


- (float)distanceTo:(NuoCoord*)other
{
    return vector_distance(_coord, other->_coord);
}


- (NuoCoord*)interpolateTo:(NuoCoord*)other byFactor:(float)factor
{
    NuoCoord* result = [NuoCoord new];
    result->_coord = _coord + (other->_coord - _coord) * factor;
    return result;
}


@end



@implementation NuoBoundingSphere

- (NuoBoundingSphere*)unionWith:(NuoBoundingSphere*)other
{
    float distance = [_center distanceTo:other.center];
    NuoBoundingSphere *smaller, *larger;
    if (_radius > other.radius)
    {
        smaller = other;
        larger = self;
    }
    else
    {
        smaller = self;
        larger = other;
    }
    
    float futhestOtherReach = distance + smaller.radius;
    float largerRadius = larger.radius;
    
    if (futhestOtherReach < largerRadius)
    {
        return larger;
    }
    else
    {
        NuoBoundingSphere* result = [NuoBoundingSphere new];
        result.radius = (distance + other.radius + _radius) / 2.0;
        
        float newCenterDistance = result.radius - _radius;
        float factor = newCenterDistance / distance;
        result.center = [_center interpolateTo:other.center byFactor:factor];
        
        return result;
    }
}

@end



@implementation NuoMeshBox
{
    NuoBoundingSphere* _sphere;
}



- (instancetype)init
{
    self = [super init];
    if (self)
    {
        _center = [NuoCoord new];
        _span = [NuoCoord new];
    }
    return self;
}



- (NuoMeshBox*)unionWith:(NuoMeshBox*)other
{
    NuoMeshBox* newBox = [NuoMeshBox new];
    vector_float3 vMin, vMax;
    
    vMin.x = std::min(_center.x - _span.x / 2.0, other.center.x - other.span.x / 2.0);
    vMax.x = std::max(_center.x + _span.x / 2.0, other.center.x + other.span.x / 2.0);
    vMin.y = std::min(_center.y - _span.y / 2.0, other.center.y - other.span.y / 2.0);
    vMax.y = std::max(_center.y + _span.y / 2.0, other.center.y + other.span.y / 2.0);
    vMin.z = std::min(_center.z - _span.z / 2.0, other.center.z - other.span.z / 2.0);
    vMax.z = std::max(_center.z + _span.z / 2.0, other.center.z + other.span.z / 2.0);
    
    newBox.center.coord = (vMin + vMax) / 2.0f;
    newBox.span.coord = vMax - vMin;
    
    return newBox;
}


- (NuoBoundingSphere*)boundingSphere
{
    if (!_sphere)
    {
        _sphere = [NuoBoundingSphere new];
        _sphere.center = _center;
        _sphere.radius = [_span maxDimension] * 1.414 / 2.0;
    }
    
    return _sphere;
}


@end




@implementation NuoMesh
{
    BOOL _hasTransparency;
    std::shared_ptr<NuoModelBase> _rawModel;
}




@synthesize indexBuffer = _indexBuffer;
@synthesize vertexBuffer = _vertexBuffer;
@synthesize boundingBoxLocal = _boundingBoxLocal;



- (instancetype)init
{
    self = [super init];
    
    if (self)
    {
        _transformPoise = matrix_identity_float4x4;
        _transformTranslate = matrix_identity_float4x4;
    }
    
    return self;
}



- (instancetype)initWithDevice:(id<MTLDevice>)device
            withVerticesBuffer:(void*)buffer withLength:(size_t)length
                   withIndices:(void*)indices withLength:(size_t)indicesLength
{
    if ((self = [super init]))
    {
        _vertexBuffer = [device newBufferWithBytes:buffer
                                            length:length
                                           options:MTLResourceOptionCPUCacheModeDefault];
        
        _indexBuffer = [device newBufferWithBytes:indices
                                           length:indicesLength
                                          options:MTLResourceOptionCPUCacheModeDefault];
        _device = device;
        _enabled = true;
        
        _smoothTolerance = 0.0f;
        _smoothConservative = YES;
        
        _rotation = [[NuoMeshRotation alloc] init];
        
        {
            id<MTLBuffer> buffers[kInFlightBufferCount];
            for (unsigned int i = 0; i < kInFlightBufferCount; ++i)
            {
                buffers[i] = [device newBufferWithLength:sizeof(NuoMeshUniforms)
                                                 options:MTLResourceOptionCPUCacheModeDefault];
            }
            _transformBuffers = [[NSArray alloc] initWithObjects:buffers count:kInFlightBufferCount];
        }
        
        _transformPoise = matrix_identity_float4x4;
        _transformTranslate = matrix_identity_float4x4;
    }
    
    return self;
}



- (instancetype)cloneForMode:(NuoMeshModeShaderParameter)mode
{
    return self;
}


- (void)shareResourcesFrom:(NuoMesh*)mesh
{
    _device = mesh.device;
    _vertexBuffer = mesh.vertexBuffer;
    _indexBuffer = mesh.indexBuffer;
    _transformBuffers = mesh.transformBuffers;
    _enabled = mesh.enabled;
    
    [self setBoundingBoxLocal:mesh.boundingBoxLocal];
}



- (void)updateBoundingSphere
{
    vector_float4 localCenter =
    {
        _boundingSphereLocal.center.x,
        _boundingSphereLocal.center.y,
        _boundingSphereLocal.center.z,
        1,
    };
    localCenter = matrix_multiply(_transformPoise, localCenter);
    localCenter = matrix_multiply(_transformTranslate, localCenter);
    
    NuoCoord* center = [NuoCoord new];
    center.x = localCenter.x;
    center.y = localCenter.y;
    center.z = localCenter.z;
    
    if (!_boundingSphere)
        _boundingSphere = [NuoBoundingSphere new];
    _boundingSphere.center = center;
    _boundingSphere.radius = _boundingSphereLocal.radius;
}



- (void)setBoundingBoxLocal:(NuoMeshBox *)boundingBox
{
    _boundingBoxLocal = boundingBox;
    _boundingSphereLocal = [_boundingBoxLocal boundingSphere];
    
    [self updateBoundingSphere];
}



- (void)setTransformTranslate:(matrix_float4x4)transformTranslate
{
    _transformTranslate = transformTranslate;
    [self updateBoundingSphere];
}



- (void)smoothWithTolerance:(float)tolerance
{
    _smoothTolerance = tolerance;
    
    std::shared_ptr<NuoModelBase> clonedModel = _rawModel;
    
    if (_smoothTolerance > 0.001)
    {
        clonedModel = _rawModel->Clone();
        clonedModel->SmoothSurface(tolerance, _smoothConservative);
    }
    
    _vertexBuffer = [_device newBufferWithBytes:clonedModel->Ptr()
                                         length:clonedModel->Length()
                                        options:MTLResourceOptionCPUCacheModeDefault];
    
    _indexBuffer = [_device newBufferWithBytes:clonedModel->IndicesPtr()
                                        length:clonedModel->IndicesLength()
                                       options:MTLResourceOptionCPUCacheModeDefault];
}


- (void)setSmoothConservative:(BOOL)smoothConservative
{
    _smoothConservative = smoothConservative;
    [self smoothWithTolerance:_smoothTolerance];
}



- (BOOL)hasUnifiedMaterial
{
    const std::shared_ptr<NuoMaterial>& material = _rawModel->GetUnifiedMaterial();
    return material != nullptr;
}



- (void)setUnifiedOpacity:(float)unifiedOpacity
{
    const std::shared_ptr<NuoMaterial>& material = _rawModel->GetUnifiedMaterial();
    if (!material)
        return;
    
    material.get()->dissolve = unifiedOpacity;
    
    _rawModel->UpdateBufferWithUnifiedMaterial();
    _vertexBuffer = [_device newBufferWithBytes:_rawModel->Ptr()
                                         length:_rawModel->Length()
                                        options:MTLResourceOptionCPUCacheModeDefault];
    
    _indexBuffer = [_device newBufferWithBytes:_rawModel->IndicesPtr()
                                        length:_rawModel->IndicesLength()
                                       options:MTLResourceOptionCPUCacheModeDefault];

    BOOL wasTrans = _hasTransparency;
    _hasTransparency = (unifiedOpacity < 0.99999);
    
    if (wasTrans != _hasTransparency)
        [self makeDepthStencilState];
}



- (float)unifiedOpacity
{
    const std::shared_ptr<NuoMaterial>& material = _rawModel->GetUnifiedMaterial();
    return material->dissolve;
}



- (void)setRawModel:(void*)model
{
    _rawModel = ((NuoModelBase*)model)->shared_from_this();
}


- (NSString*)modelName
{
    if (_rawModel)
    {
        NSString* name = [[NSString alloc] initWithUTF8String:_rawModel->GetName().c_str()];
        return name;
    }
    
    return nil;
}


- (MTLRenderPipelineDescriptor*)makePipelineStateDescriptor
{
    id<MTLLibrary> library = [self.device newDefaultLibrary];
    
    NSString* vertexFunc = _shadowPipelineState ? @"vertex_project_shadow" : @"vertex_project";
    NSString* fragmnFunc = _shadowPipelineState ? @"fragment_light_shadow" : @"fragment_light";
    
    // there is material and color, not only shadow overlay
    //
    BOOL shadowOverlay = NO;
    int meshMode = kMeshMode_Normal;
    MTLFunctionConstantValues* funcConstant = [MTLFunctionConstantValues new];
    [funcConstant setConstantValue:&shadowOverlay type:MTLDataTypeBool atIndex:3];
    [funcConstant setConstantValue:&kShadowPCSS type:MTLDataTypeBool atIndex:4];
    [funcConstant setConstantValue:&kShadowPCF type:MTLDataTypeBool atIndex:5];
    [funcConstant setConstantValue:&meshMode type:MTLDataTypeInt atIndex:6];
    
    MTLRenderPipelineDescriptor *pipelineDescriptor = [MTLRenderPipelineDescriptor new];
    pipelineDescriptor.vertexFunction = [library newFunctionWithName:vertexFunc];
    pipelineDescriptor.fragmentFunction = [library newFunctionWithName:fragmnFunc
                                                        constantValues:funcConstant
                                                                 error:nil];
    pipelineDescriptor.sampleCount = kSampleCount;
    pipelineDescriptor.colorAttachments[0].pixelFormat = MTLPixelFormatBGRA8Unorm;
    pipelineDescriptor.depthAttachmentPixelFormat = MTLPixelFormatDepth32Float;
    
    MTLRenderPipelineColorAttachmentDescriptor* colorAttachment = pipelineDescriptor.colorAttachments[0];
    colorAttachment.blendingEnabled = YES;
    colorAttachment.rgbBlendOperation = MTLBlendOperationAdd;
    colorAttachment.alphaBlendOperation = MTLBlendOperationAdd;
    colorAttachment.sourceRGBBlendFactor = MTLBlendFactorSourceAlpha;
    colorAttachment.destinationRGBBlendFactor = MTLBlendFactorOneMinusSourceAlpha;
    colorAttachment.destinationAlphaBlendFactor = MTLBlendFactorOneMinusSourceAlpha;
    
    return pipelineDescriptor;
}

- (void)makePipelineState:(MTLRenderPipelineDescriptor*)pipelineDescriptor
{
    NSError *error = nil;
    _renderPipelineState = [self.device newRenderPipelineStateWithDescriptor:pipelineDescriptor
                                                                       error:&error];
}

- (void)makePipelineScreenSpaceStateWithVertexShader:(NSString*)vertexShader
                                  withFragemtnShader:(NSString*)fragmentShader
{
    id<MTLLibrary> library = [self.device newDefaultLibrary];
    
    MTLRenderPipelineDescriptor *screenSpacePipelineDescriptor = [MTLRenderPipelineDescriptor new];
    screenSpacePipelineDescriptor.vertexFunction = [library newFunctionWithName:vertexShader];
    screenSpacePipelineDescriptor.fragmentFunction = [library newFunctionWithName:fragmentShader];
    screenSpacePipelineDescriptor.sampleCount = kSampleCount;
    screenSpacePipelineDescriptor.colorAttachments[0].pixelFormat = MTLPixelFormatRGBA16Float;
    screenSpacePipelineDescriptor.colorAttachments[1].pixelFormat = MTLPixelFormatRGBA16Float;
    screenSpacePipelineDescriptor.colorAttachments[2].pixelFormat = MTLPixelFormatRGBA16Float;
    screenSpacePipelineDescriptor.depthAttachmentPixelFormat = MTLPixelFormatDepth32Float;
    
    NSError *error = nil;
    _screenSpacePipelineState = [self.device newRenderPipelineStateWithDescriptor:screenSpacePipelineDescriptor
                                                                            error:&error];
}

- (void)makePipelineScreenSpaceState
{
    [self makePipelineScreenSpaceStateWithVertexShader:@"vertex_project_screen_space"
                                    withFragemtnShader:@"fragement_screen_space"];
}
    
- (void)makePipelineShadowState:(NSString*)vertexShadowShader
{
    id<MTLLibrary> library = [self.device newDefaultLibrary];
    
    MTLRenderPipelineDescriptor *shadowPipelineDescriptor = [MTLRenderPipelineDescriptor new];
    shadowPipelineDescriptor.vertexFunction = [library newFunctionWithName:vertexShadowShader];
    shadowPipelineDescriptor.fragmentFunction = nil;
    shadowPipelineDescriptor.sampleCount = 1 /*kSampleCount*/;
    shadowPipelineDescriptor.colorAttachments[0].pixelFormat = MTLPixelFormatInvalid;
    shadowPipelineDescriptor.depthAttachmentPixelFormat = MTLPixelFormatDepth32Float;
    
    NSError *error = nil;
    _shadowPipelineState = [self.device newRenderPipelineStateWithDescriptor:shadowPipelineDescriptor
                                                                       error:&error];
}

- (void)makePipelineShadowState
{
    return [self makePipelineShadowState:@"vertex_shadow"];
}

- (void)makeDepthStencilState
{
    MTLDepthStencilDescriptor *depthStencilDescriptor = [MTLDepthStencilDescriptor new];
    depthStencilDescriptor.depthCompareFunction = MTLCompareFunctionLess;
    
    if (self.hasTransparency)
        depthStencilDescriptor.depthWriteEnabled = NO;
    else
        depthStencilDescriptor.depthWriteEnabled = YES;
    
    _depthStencilState = [self.device newDepthStencilStateWithDescriptor:depthStencilDescriptor];
}



- (void)updateUniform:(NSInteger)bufferIndex withTransform:(matrix_float4x4)transform
{
    matrix_float4x4 localTransform = matrix_multiply(_transformTranslate, _transformPoise);
    if (_rotation)
        localTransform = matrix_multiply(localTransform, _rotation.rotationMatrix);
    transform = matrix_multiply(transform, localTransform);
    
    NuoMeshUniforms uniforms;
    uniforms.transform = transform;
    uniforms.normalTransform = matrix_extract_linear(uniforms.transform);
    memcpy([_transformBuffers[bufferIndex] contents], &uniforms, sizeof(uniforms));
}



- (void)drawMesh:(id<MTLRenderCommandEncoder>)renderPass indexBuffer:(NSInteger)index
{
    [renderPass setFrontFacingWinding:MTLWindingCounterClockwise];
    [renderPass setRenderPipelineState:_renderPipelineState];
    [renderPass setDepthStencilState:_depthStencilState];
    
    NSUInteger rotationIndex = _shadowPipelineState ? 3 : 2;
    
    [renderPass setVertexBuffer:_vertexBuffer offset:0 atIndex:0];
    [renderPass setVertexBuffer:_transformBuffers[index] offset:0 atIndex:rotationIndex];
    [renderPass drawIndexedPrimitives:MTLPrimitiveTypeTriangle
                           indexCount:[_indexBuffer length] / sizeof(uint32_t)
                            indexType:MTLIndexTypeUInt32
                          indexBuffer:_indexBuffer
                    indexBufferOffset:0];
}


- (void)drawScreenSpace:(id<MTLRenderCommandEncoder>)renderPass indexBuffer:(NSInteger)index
{
    [renderPass setFrontFacingWinding:MTLWindingCounterClockwise];
    [renderPass setRenderPipelineState:_screenSpacePipelineState];
    [renderPass setDepthStencilState:_depthStencilState];
    
    NSUInteger rotationIndex = _shadowPipelineState ? 3 : 2;
    
    [renderPass setVertexBuffer:_vertexBuffer offset:0 atIndex:0];
    [renderPass setVertexBuffer:_transformBuffers[index] offset:0 atIndex:rotationIndex];
    [renderPass drawIndexedPrimitives:MTLPrimitiveTypeTriangle
                           indexCount:[_indexBuffer length] / sizeof(uint32_t)
                            indexType:MTLIndexTypeUInt32
                          indexBuffer:_indexBuffer
                    indexBufferOffset:0];
}


- (void)drawShadow:(id<MTLRenderCommandEncoder>)renderPass indexBuffer:(NSInteger)index
{
    if (_shadowPipelineState)
    {
        [renderPass setFrontFacingWinding:MTLWindingCounterClockwise];
        [renderPass setRenderPipelineState:_shadowPipelineState];
        [renderPass setDepthStencilState:_depthStencilState];
        
        [renderPass setVertexBuffer:_vertexBuffer offset:0 atIndex:0];
        [renderPass setVertexBuffer:_transformBuffers[index] offset:0 atIndex:2];
        [renderPass drawIndexedPrimitives:MTLPrimitiveTypeTriangle
                               indexCount:[_indexBuffer length] / sizeof(uint32_t)
                                indexType:MTLIndexTypeUInt32
                              indexBuffer:_indexBuffer
                        indexBufferOffset:0];
    }
}


- (BOOL)hasTransparency
{
    return _hasTransparency;
}


- (void)setTransparency:(BOOL)transparent
{
    _hasTransparency = transparent;
}



- (void)centerMesh
{
    NuoMeshBox* bounding = _boundingBoxLocal;
    const vector_float3 translationToCenter =
    {
        - bounding.center.x,
        - bounding.center.y,
        - bounding.center.z
    };
    const matrix_float4x4 modelCenteringMatrix = matrix_translation(translationToCenter);
    _transformPoise = modelCenteringMatrix;
    
    [self updateBoundingSphere];
}


@end





NuoMesh* CreateMesh(const NuoModelOption& options,
                    id<MTLDevice> device, id<MTLCommandQueue> commandQueue,
                    const std::shared_ptr<NuoModelBase> model)
{
    NuoMesh* resultMesh = nil;
    
    if (!options._textured && !options._basicMaterialized)
    {
        NuoMesh* mesh = [[NuoMesh alloc] initWithDevice:device
                                     withVerticesBuffer:model->Ptr()
                                             withLength:model->Length()
                                            withIndices:model->IndicesPtr()
                                             withLength:model->IndicesLength()];
        
        resultMesh = mesh;
    }
    else if (options._textured && !options._basicMaterialized)
    {
        NSString* modelTexturePath = [NSString stringWithUTF8String:model->GetTexturePathDiffuse().c_str()];
        BOOL checkTransparency = options._textureEmbedMaterialTransparency;
        
        NuoMeshTextured* mesh = [[NuoMeshTextured alloc] initWithDevice:device
                                                     withVerticesBuffer:model->Ptr()
                                                             withLength:model->Length()
                                                            withIndices:model->IndicesPtr()
                                                             withLength:model->IndicesLength()];
        
        [mesh makeTexture:modelTexturePath checkTransparency:checkTransparency withCommandQueue:commandQueue];
        
        resultMesh = mesh;
    }
    else if (options._textured && options._basicMaterialized)
    {
        NSString* modelTexturePath = [NSString stringWithUTF8String:model->GetTexturePathDiffuse().c_str()];
        BOOL embeddedAlpha = options._textureEmbedMaterialTransparency;
        
        NuoMeshTexMatieraled* mesh = [[NuoMeshTexMatieraled alloc] initWithDevice:device
                                         withVerticesBuffer:model->Ptr()
                                                 withLength:model->Length()
                                                withIndices:model->IndicesPtr()
                                                 withLength:model->IndicesLength()];
        
        [mesh makeTexture:modelTexturePath checkTransparency:embeddedAlpha withCommandQueue:commandQueue];
        
        NSString* modelTexturePathOpacity = [NSString stringWithUTF8String:model->GetTexturePathOpacity().c_str()];
        if ([modelTexturePathOpacity isEqualToString:@""])
            modelTexturePathOpacity = nil;
        if (modelTexturePathOpacity)
            [mesh makeTextureOpacity:modelTexturePathOpacity withCommandQueue:commandQueue];
        
        NSString* modelTexturePathBump = [NSString stringWithUTF8String:model->GetTexturePathBump().c_str()];
        if ([modelTexturePathBump isEqualToString:@""])
            modelTexturePathBump = nil;
        if (modelTexturePathBump)
            [mesh makeTextureBump:modelTexturePathBump withCommandQueue:commandQueue];
        
        if (model->HasTransparent() || modelTexturePathOpacity)
            [mesh setTransparency:YES];
        else if (!embeddedAlpha)
            [mesh setTransparency:NO];
        
        [mesh setIgnoreTexutreAlpha:!embeddedAlpha];
        [mesh setPhysicallyReflection:options._physicallyReflection];
        
        resultMesh = mesh;
    }
    else if (!options._textured && options._basicMaterialized)
    {
        NuoMeshMatieraled* mesh = [[NuoMeshMatieraled alloc] initWithDevice:device
                                                         withVerticesBuffer:model->Ptr()
                                                                 withLength:model->Length()
                                                                withIndices:model->IndicesPtr()
                                                                 withLength:model->IndicesLength()];
        
        [mesh setTransparency:model->HasTransparent()];
        [mesh setPhysicallyReflection:options._physicallyReflection];
        
        resultMesh = mesh;
    }
    
    [resultMesh setRawModel:model.get()];
    [resultMesh makePipelineScreenSpaceState];
    [resultMesh makePipelineShadowState];
    [resultMesh makePipelineState:[resultMesh makePipelineStateDescriptor]];
    [resultMesh makeDepthStencilState];
    return resultMesh;
}


