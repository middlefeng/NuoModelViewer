
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



@implementation NuoCoord


- (float)maxDimension
{
    float max = std::max(_x, _y);
    return std::max(max, _z);
}


- (float)distanceTo:(NuoCoord*)other
{
    vector_float3 v1 = { _x, _y, _z };
    vector_float3 v2 = { other.x, other.y, other.z };
    
    return vector_distance(v1, v2);
}


- (NuoCoord*)interpolateTo:(NuoCoord*)other byFactor:(float)factor
{
    NuoCoord* result = [NuoCoord new];
    result.x = _x + (other.x - _x) * factor;
    result.y = _x + (other.y - _y) * factor;
    result.z = _z + (other.z - _z) * factor;
    
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
    
    if (futhestOtherReach < _radius)
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
    
    float xMin = std::min(_center.x - _span.x / 2.0, other.center.x - other.span.x / 2.0);
    float xMax = std::max(_center.x + _span.x / 2.0, other.center.x + other.span.x / 2.0);
    float yMin = std::min(_center.y - _span.y / 2.0, other.center.y - other.span.y / 2.0);
    float yMax = std::max(_center.y + _span.y / 2.0, other.center.y + other.span.y / 2.0);
    float zMin = std::min(_center.z - _span.z / 2.0, other.center.z - other.span.z / 2.0);
    float zMax = std::max(_center.z + _span.z / 2.0, other.center.z + other.span.z / 2.0);
    
    newBox.center.x = (xMax + xMin) / 2.0f;
    newBox.center.y = (yMax + yMin) / 2.0f;
    newBox.center.z = (zMax + zMin) / 2.0f;
    
    newBox.span.x = xMax - xMin;
    newBox.span.y = yMax - yMin;
    newBox.span.z = zMax - zMin;
    
    return newBox;
}


- (NuoBoundingSphere*)boundingSphere
{
    if (!_sphere)
    {
        _sphere = [NuoBoundingSphere new];
        _sphere.center = _center;
        _sphere.radius = [_span maxDimension] * 1.41 / 2.0;
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
@synthesize boundingBox = _boundingBox;





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
            id<MTLBuffer> buffers1[kInFlightBufferCount];
            for (unsigned int i = 0; i < kInFlightBufferCount; ++i)
            {
                buffers1[i] = [device newBufferWithLength:sizeof(NuoMeshUniforms) options:MTLResourceOptionCPUCacheModeDefault];
            }
            _transformBuffers = [[NSArray alloc] initWithObjects:buffers1 count:kInFlightBufferCount];
        }
        
        _transformPoise = matrix_identity_float4x4;
        _transformTranslate = matrix_identity_float4x4;
    }
    
    return self;
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



- (void)setBoundingBox:(NuoMeshBox *)boundingBox
{
    _boundingBox = boundingBox;
    _boundingSphereLocal = [boundingBox boundingSphere];
    
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
    
    MTLRenderPipelineDescriptor *pipelineDescriptor = [MTLRenderPipelineDescriptor new];
    pipelineDescriptor.vertexFunction = [library newFunctionWithName:vertexFunc];
    pipelineDescriptor.fragmentFunction = [library newFunctionWithName:fragmnFunc];
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
    
- (void)makePipelineShadowState:(NSString*)vertexShadowShader
{
    id<MTLLibrary> library = [self.device newDefaultLibrary];
    
    MTLRenderPipelineDescriptor *shadowPipelineDescriptor = [MTLRenderPipelineDescriptor new];
    shadowPipelineDescriptor.vertexFunction = [library newFunctionWithName:vertexShadowShader];
    shadowPipelineDescriptor.fragmentFunction = [library newFunctionWithName:@"fragment_shadow"];;
    shadowPipelineDescriptor.sampleCount = kSampleCount;
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
    NuoMeshBox* bounding = _boundingBox;
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
    [resultMesh makePipelineShadowState];
    [resultMesh makePipelineState:[resultMesh makePipelineStateDescriptor]];
    [resultMesh makeDepthStencilState];
    return resultMesh;
}


