
#import <Metal/Metal.h>

#include "NuoMeshOptions.h"
#include "NuoMeshRotation.h"
#include "NuoUniforms.h"

#include "NuoMathVector.h"
#include "NuoMeshBounds.h"
#include "NuoModelBase.h"

#import "NuoRenderPassEncoder.h"

@protocol NuoRenderInFlight;




/**
 *
 
     NuoRenderPass
        NuoShadowMapRenderer
        NuoDeferredRenderer
        NuoRenderPipelinePass
            NuoMeshSceneRenderPass
                NuoScreenSpaceRenderer
                (App Classes ...)
     
 */




@interface NuoMesh : NSObject


@property (nonatomic, readonly) id<MTLDevice> device;
@property (nonatomic, readonly) id<MTLLibrary> library;
@property (nonatomic, strong) id<MTLCommandQueue> commandQueue;
@property (nonatomic, strong) id<MTLRenderPipelineState> renderPipelineState;
@property (nonatomic, strong) id<MTLRenderPipelineState> screenSpacePipelineState;
@property (nonatomic, strong) id<MTLRenderPipelineState> shadowPipelineState;
@property (nonatomic, strong) id<MTLDepthStencilState> depthStencilState;

@property (nonatomic, readonly, assign) float smoothTolerance;
@property (nonatomic, assign) BOOL smoothConservative;



@property (nonatomic, assign) NSUInteger sampleCount;
@property (nonatomic, assign) BOOL shadowOptionPCSS;
@property (nonatomic, assign) BOOL shadowOptionPCF;
@property (nonatomic, assign) BOOL shadowOptionRayTracing;



// mesh rotation in model coordinate, around given axis.
// better for script-based rotation
//
@property (nonatomic, assign) NuoMeshRotation rotation;

// mesh transform about the poise (rotation around model center).
// note this transform may include a slight translation before rotation
// because the model need to be centered (usually around its bounding box)
//
@property (nonatomic, assign) NuoMatrixFloat44 transformPoise;

// mesh transform about the translate in the world coordinate
//
@property (nonatomic, assign) NuoMatrixFloat44 transformTranslate;

// all (prior view-matrix) mesh-transforms concatenate and passed to GPU
//
@property (nonatomic, strong) NuoBufferInFlight* transformBuffers;



// unified material (common to all vertices)
//
@property (nonatomic, assign, readonly) BOOL hasUnifiedMaterial;
@property (nonatomic, assign) float unifiedOpacity;

@property (nonatomic, assign) BOOL reverseCommonCullMode;


@property (nonatomic, readonly) id<MTLBuffer> vertexBuffer;
@property (nonatomic, readonly) id<MTLBuffer> indexBuffer;

@property (nonatomic, assign) NuoMeshBounds boundsLocal;
@property (nonatomic, assign) BOOL enabled;
@property (nonatomic, assign) BOOL cullEnabled;


- (instancetype)initWithCommandQueue:(id<MTLCommandQueue>)commandQueue
                  withVerticesBuffer:(void*)buffer withLength:(size_t)length
                         withIndices:(void*)indices withLength:(size_t)indicesLength;

// get a clone of the current mesh for debugging purpose.
// the cloned version shall share most of GPU resources.
//
- (instancetype)cloneForMode:(NuoMeshModeShaderParameter)mode;


- (void)makePipelineState;
- (void)makeDepthStencilState;
- (void)applyTransmissionBlending:(MTLRenderPipelineColorAttachmentDescriptor*)colorAttachment;

- (void)makeGPUStates;


- (std::vector<NuoRayMask>)maskBuffer;


- (void)setRawModel:(const PNuoModelBase&)model;
- (NSString*)modelName;
- (void)smoothWithTolerance:(float)tolerance;

// the "transform" should be the outter world transform (excluding the view matrix,
// that is, the returned buffer is in the world coordinate rather than in the camera coordinate)
//
- (void)appendWorldBuffers:(const NuoMatrixFloat44&)transform toBuffers:(NuoGlobalBuffers*)buffers;
- (BOOL)isCachedTransformValid:(const NuoMatrixFloat44&)transform;
- (void)invalidCachedTransform;

- (void)updateUniform:(id<NuoRenderInFlight>)inFlight withTransform:(const NuoMatrixFloat44&)transform;
- (void)drawMesh:(NuoRenderPassEncoder*)renderPass;
- (void)drawScreenSpace:(NuoRenderPassEncoder*)renderPass;
- (void)drawShadow:(NuoRenderPassEncoder*)renderPass;
- (BOOL)hasTransparency;
- (void)setTransparency:(BOOL)transparent;

- (NuoMeshBounds)worldBounds:(const NuoMatrixFloat44&)transform;

- (void)centerMesh;

/**
 *  this is expensive operation as private buffers are supposed not to be updated frequently
 */
+ (void)updatePrivateBuffer:(id<MTLBuffer>)buffer
           withCommandQueue:(id<MTLCommandQueue>)commandQueue
                   withData:(void*)data withSize:(size_t)size;


@end


#if __cplusplus

#include <memory>


class NuoModelBase;
class NuoModelOption;

NuoMesh* CreateMesh(const NuoMeshOptions& options,
                    id<MTLCommandQueue> commandQueue,
                    const std::shared_ptr<NuoModelBase> model);

#endif


