
#import <Metal/Metal.h>

#include "NuoMeshOptions.h"
#include "NuoMeshRotation.h"



@interface NuoMeshBox : NSObject

@property (nonatomic, assign) float centerX;
@property (nonatomic, assign) float centerY;
@property (nonatomic, assign) float centerZ;

@property (nonatomic, assign) float spanX;
@property (nonatomic, assign) float spanY;
@property (nonatomic, assign) float spanZ;

- (NuoMeshBox*)unionWith:(NuoMeshBox*)other;

@end



@interface NuoMesh : NSObject


@property (nonatomic, strong) id<MTLDevice> device;
@property (nonatomic, strong) id<MTLRenderPipelineState> renderPipelineState;
@property (nonatomic, strong) id<MTLRenderPipelineState> shadowPipelineState;
@property (nonatomic, strong) id<MTLDepthStencilState> depthStencilState;

@property (nonatomic, readonly, assign) float smoothTolerance;
@property (nonatomic, assign) BOOL smoothConservative;

// mesh rotation in model coordinate
//
@property (nonatomic, strong) NuoMeshRotation* rotation;
@property (nonatomic, strong) NSArray<id<MTLBuffer>>* rotationBuffers;

// mesh generic transform
@property (nonatomic, assign) matrix_float4x4 transform;

// unified material (common to all vertices)
//
@property (nonatomic, assign, readonly) BOOL hasUnifiedMaterial;
@property (nonatomic, assign) float unifiedOpacity;

@property (nonatomic, assign) BOOL reverseCommonCullMode;


@property (nonatomic, readonly) id<MTLBuffer> vertexBuffer;
@property (nonatomic, readonly) id<MTLBuffer> indexBuffer;

@property (nonatomic, strong) NuoMeshBox* boundingBox;
@property (nonatomic, assign) BOOL enabled;


- (instancetype)initWithDevice:(id<MTLDevice>)device
            withVerticesBuffer:(void*)buffer withLength:(size_t)length
                   withIndices:(void*)indices withLength:(size_t)indicesLength;

- (MTLRenderPipelineDescriptor*)makePipelineStateDescriptor;
- (void)makePipelineShadowState:(NSString*)vertexShadowShader;
- (void)makePipelineState:(MTLRenderPipelineDescriptor*)pipelineDescriptor;
- (void)makeDepthStencilState;


- (void)setRawModel:(void*)model;
- (NSString*)modelName;
- (void)smoothWithTolerance:(float)tolerance;


- (void)updateUniform:(NSInteger)bufferIndex withTransform:(matrix_float4x4)transform;
- (void)drawMesh:(id<MTLRenderCommandEncoder>)renderPass indexBuffer:(NSInteger)index;
- (void)drawShadow:(id<MTLRenderCommandEncoder>)renderPass indexBuffer:(NSInteger)index;
- (BOOL)hasTransparency;
- (void)setTransparency:(BOOL)transparent;


@end


#if __cplusplus

#include <memory>


class NuoModelBase;
class NuoModelOption;

NuoMesh* CreateMesh(const NuoModelOption& options,
                    id<MTLDevice> device, id<MTLCommandQueue> commandQueue,
                    const std::shared_ptr<NuoModelBase> model);

#endif


