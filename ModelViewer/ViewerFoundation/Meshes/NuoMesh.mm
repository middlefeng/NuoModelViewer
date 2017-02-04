
#import "NuoMesh.h"

#include "tiny_obj_loader.h"

#include "NuoModelBase.h"
#include "NuoTypes.h"
#include "NuoMaterial.h"

#import <Cocoa/Cocoa.h>
#import "NuoMeshTextured.h"
#import "NuoMeshTexMatieraled.h"
#import "NuoMeshUniform.h"



@implementation NuoMeshBox


- (NuoMeshBox*)unionWith:(NuoMeshBox*)other
{
    NuoMeshBox* newBox = [NuoMeshBox new];
    
    float xMin = std::min(_centerX - _spanX / 2.0, other.centerX - other.spanX / 2.0);
    float xMax = std::max(_centerX + _spanX / 2.0, other.centerX + other.spanX / 2.0);
    float yMin = std::min(_centerY - _spanY / 2.0, other.centerY - other.spanY / 2.0);
    float yMax = std::max(_centerY + _spanY / 2.0, other.centerY + other.spanY / 2.0);
    float zMin = std::min(_centerZ - _spanZ / 2.0, other.centerZ - other.spanZ / 2.0);
    float zMax = std::max(_centerZ + _spanZ / 2.0, other.centerZ + other.spanZ / 2.0);
    
    newBox.centerX = (xMax + xMin) / 2.0f;
    newBox.centerY = (yMax + yMin) / 2.0f;
    newBox.centerZ = (zMax + zMin) / 2.0f;
    
    newBox.spanX = xMax - xMin;
    newBox.spanY = yMax - yMin;
    newBox.spanZ = zMax - zMin;
    
    return newBox;
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
            id<MTLBuffer> buffers1[kInFlightBufferCount], buffers2[kInFlightBufferCount];
            for (unsigned int i = 0; i < kInFlightBufferCount; ++i)
            {
                buffers1[i] = [device newBufferWithLength:sizeof(MeshUniforms) options:MTLResourceOptionCPUCacheModeDefault];
                buffers2[i] = [device newBufferWithLength:sizeof(MeshUniforms) options:MTLResourceOptionCPUCacheModeDefault];
            }
            _rotationBuffers = [[NSArray alloc] initWithObjects:buffers1 count:kInFlightBufferCount];
            _rotationBuffersShadow = [[NSArray alloc] initWithObjects:buffers2 count:kInFlightBufferCount];
        }
    }
    
    return self;
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

    
    _hasTransparency = (unifiedOpacity < 0.99999);
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
    
    depthStencilDescriptor.depthWriteEnabled = !self.hasTransparency;
    
    _depthStencilState = [self.device newDepthStencilStateWithDescriptor:depthStencilDescriptor];
}



- (void)updateUniform:(NSInteger)bufferIndex
{
    MeshUniforms uniforms;
    uniforms.transform = _rotation.rotationMatrix;
    uniforms.normalTransform = _rotation.rotationNormalMatrix;
    memcpy([_rotationBuffers[bufferIndex] contents], &uniforms, sizeof(uniforms));
    memcpy([_rotationBuffersShadow[bufferIndex] contents], &uniforms, sizeof(uniforms));
}



- (void)drawMesh:(id<MTLRenderCommandEncoder>)renderPass indexBuffer:(NSInteger)index
{
    [self updateUniform:index];
    
    [renderPass setFrontFacingWinding:MTLWindingCounterClockwise];
    [renderPass setRenderPipelineState:_renderPipelineState];
    [renderPass setDepthStencilState:_depthStencilState];
    
    NSUInteger rotationIndex = _shadowPipelineState ? 3 : 2;
    
    [renderPass setVertexBuffer:_vertexBuffer offset:0 atIndex:0];
    [renderPass setVertexBuffer:_rotationBuffers[index] offset:0 atIndex:rotationIndex];
    [renderPass drawIndexedPrimitives:MTLPrimitiveTypeTriangle
                           indexCount:[_indexBuffer length] / sizeof(uint32_t)
                            indexType:MTLIndexTypeUInt32
                          indexBuffer:_indexBuffer
                    indexBufferOffset:0];
}


- (void)drawShadow:(id<MTLRenderCommandEncoder>)renderPass indexBuffer:(NSInteger)index
{
    [self updateUniform:index];
    
    if (_shadowPipelineState)
    {
        [renderPass setFrontFacingWinding:MTLWindingCounterClockwise];
        [renderPass setRenderPipelineState:_shadowPipelineState];
        [renderPass setDepthStencilState:_depthStencilState];
        
        [renderPass setVertexBuffer:_vertexBuffer offset:0 atIndex:0];
        [renderPass setVertexBuffer:_rotationBuffersShadow[index] offset:0 atIndex:2];
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
        
        resultMesh = mesh;
    }
    
    [resultMesh setRawModel:model.get()];
    [resultMesh makePipelineShadowState];
    [resultMesh makePipelineState:[resultMesh makePipelineStateDescriptor]];
    [resultMesh makeDepthStencilState];
    return resultMesh;
}


