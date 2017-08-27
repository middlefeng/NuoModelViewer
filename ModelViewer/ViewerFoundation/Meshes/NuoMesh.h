
#import <Metal/Metal.h>

#include "NuoMeshOptions.h"
#include "NuoMeshRotation.h"
#include "NuoUniforms.h"



extern const BOOL kShadowPCSS;
extern const BOOL kShadowPCF;



@interface NuoCoord : NSObject

@property (nonatomic, assign) float x;
@property (nonatomic, assign) float y;
@property (nonatomic, assign) float z;

- (float)maxDimension;
- (float)distanceTo:(NuoCoord*)other;
- (NuoCoord*)interpolateTo:(NuoCoord*)other byFactor:(float)factor;

@end



@interface NuoBoundingSphere : NSObject

@property (nonatomic, strong) NuoCoord* center;
@property (nonatomic, assign) float radius;

- (NuoBoundingSphere*)unionWith:(NuoBoundingSphere*)other;

@end



@interface NuoMeshBox : NSObject

@property (nonatomic, strong) NuoCoord* center;
@property (nonatomic, strong) NuoCoord* span;

- (NuoMeshBox*)unionWith:(NuoMeshBox*)other;
- (NuoBoundingSphere*)boundingSphere;

@end



@interface NuoMesh : NSObject


@property (nonatomic, strong) id<MTLDevice> device;
@property (nonatomic, strong) id<MTLRenderPipelineState> renderPipelineState;
@property (nonatomic, strong) id<MTLRenderPipelineState> shadowPipelineState;
@property (nonatomic, strong) id<MTLDepthStencilState> depthStencilState;

@property (nonatomic, readonly, assign) float smoothTolerance;
@property (nonatomic, assign) BOOL smoothConservative;



// mesh rotation in model coordinate, around given axis.
// better for script-based rotation
//
@property (nonatomic, strong) NuoMeshRotation* rotation;

// mesh transform about the poise (rotation around model center).
// note this transform may include a slight translation before rotation
// because the model need to be centered (usually around its bounding box)
//
@property (nonatomic, assign) matrix_float4x4 transformPoise;

// mesh transform about the translate in the world coordinate
//
@property (nonatomic, assign) matrix_float4x4 transformTranslate;

// all (prior view-matrix) mesh-transforms concatenate and passed to GPU
//
@property (nonatomic, strong) NSArray<id<MTLBuffer>>* transformBuffers;



// unified material (common to all vertices)
//
@property (nonatomic, assign, readonly) BOOL hasUnifiedMaterial;
@property (nonatomic, assign) float unifiedOpacity;

@property (nonatomic, assign) BOOL reverseCommonCullMode;


@property (nonatomic, readonly) id<MTLBuffer> vertexBuffer;
@property (nonatomic, readonly) id<MTLBuffer> indexBuffer;

@property (nonatomic, strong) NuoMeshBox* boundingBoxLocal;
@property (nonatomic, strong, readonly) NuoBoundingSphere* boundingSphereLocal;
@property (nonatomic, strong, readonly) NuoBoundingSphere* boundingSphere;
@property (nonatomic, assign) BOOL enabled;
@property (nonatomic, assign) BOOL cullEnabled;


- (instancetype)initWithDevice:(id<MTLDevice>)device
            withVerticesBuffer:(void*)buffer withLength:(size_t)length
                   withIndices:(void*)indices withLength:(size_t)indicesLength;

- (instancetype)cloneForMode:(MeshMode)mode;

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


- (void)centerMesh;


@end


#if __cplusplus

#include <memory>


class NuoModelBase;
class NuoModelOption;

NuoMesh* CreateMesh(const NuoModelOption& options,
                    id<MTLDevice> device, id<MTLCommandQueue> commandQueue,
                    const std::shared_ptr<NuoModelBase> model);

#endif


