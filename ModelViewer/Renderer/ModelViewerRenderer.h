
#import "ModelView.h"

#import "NuoUniforms.h"
#import "NuoTypes.h"
#import "NuoMeshSceneRenderPass.h"

#import "ModelState.h"
#import "ModelRenderDelegate.h"


@class NuoMesh;
@class NuoMeshCompound;
@class NuoMeshSceneRoot;
@class NuoBoardMesh;
@class NuoCubeMesh;
@class NuoBackdropMesh;
@class NuoLightSource;
@class NuoRayAccelerateStructure;

@class ModelSceneParameters;

class NuoMeshOption;

/**
 TERMS:
     - view is usually used in the context only coordinate frames involved. the scope (volume)
       is infinite or indefinite.
     - scene is usually used when it is critical to know the scope (or span) of visible objects (mesh)
       occupying the space (e.g. when talking about the center or span, or near-far scope).
 */


/**

 Class hierachy: asterisk (*) indicates renderers that support dynamic MSAA sampling count change
 
 NuoRenderPass
    NuoShadowMapRenderer
    NuoDeferredRenderer                (*)
    NuoRenderPipelinePass
        NotationRenderer
        MotionBlurRenderer
        NuoMeshSceneRenderPass
            NuoScreenSpaceRenderer    (*)
            ModelDissectRenderer
            ModelRenderer             (*)
 
 */


class NuoLua;



@interface ModelRenderer : NuoRenderPipelinePass


@property (readonly) ModelState* modelState;

@property (nonatomic, strong) NSArray<NuoLightSource*>* lights;
@property (nonatomic, strong) NuoCubeMesh* cubeMesh;
@property (nonatomic, strong) NuoBackdropMesh* backdropMesh;
@property (nonatomic, readonly) BOOL hasMeshes;


@property (nonatomic, assign) float backdropScaleDelta;
@property (nonatomic, assign) float backdropTransXDelta;
@property (nonatomic, assign) float backdropTransYDelta;

// delta control to the selected model
//
@property (nonatomic, assign) float zoomDelta;
@property (nonatomic, assign) float rotationXDelta;
@property (nonatomic, assign) float rotationYDelta;
@property (nonatomic, assign) float transXDelta;
@property (nonatomic, assign) float transYDelta;


// support to hybrid ray tracing
//
@property (nonatomic, assign) RecordStatus rayTracingRecordStatus;

@property (nonatomic, readonly) ModelSceneParameters* sceneParameters;

@property (nonatomic, assign) float fieldOfView;
@property (nonatomic, assign) float illuminationStrength;
@property (nonatomic, assign) float ambientDensity;

@property (nonatomic, assign) BOOL showCheckerboard;


- (instancetype)initWithCommandQueue:(id<MTLCommandQueue>)commandQueue;

- (void)loadMesh:(NSString*)path withProgress:(NuoProgressFunction)progress;
- (BOOL)loadPackage:(NSString*)path withProgress:(NuoProgressFunction)progress;
- (BOOL)isValidPack:(NSString*)path;

- (NSArray<NuoMesh*>*)configurableMeshParts;
- (NuoMeshCompound*)mainModelMesh;
- (void)setAdvancedShaowEnabled:(BOOL)enabled;

- (NSString*)exportSceneAsString:(CGSize)canvasSize;
- (void)importScene:(NuoLua*)lua;

- (void)updateModelOptionsWithProgress:(NuoProgressFunction)progress;

- (void)createBoard:(CGSize)size withName:(NSString*)name;
- (void)removeSelectedMesh;
- (void)selectMeshWithScreen:(CGPoint)point;

- (void)setResolveDepth:(BOOL)resolveDepth;
- (void)setAmbientParameters:(const NuoAmbientUniformField&)ambientParameters;
- (const NuoAmbientUniformField&)ambientParameters;

- (NuoMeshSceneRoot*)cloneSceneFor:(NuoMeshModeShaderParameter)mode;
- (void)rebuildRayTracingBuffers;
- (void)syncRayTracingBuffers;

- (void)switchToHybrid;
- (void)switchToRayTracing;

- (void)beginUserInteract;
- (void)continueUserInteract;
- (void)endUserInteract:(RecordStatus)recordStatus;


@end
