
#import "ModelView.h"

#import "NuoUniforms.h"
#import "NuoTypes.h"
#import "NuoMeshSceneRenderPass.h"


@class NuoMesh;
@class NuoMeshOption;
@class NuoLua;
@class NuoMeshCompound;
@class NuoBoardMesh;
@class NuoCubeMesh;
@class NuoBackdropMesh;
@class NuoLightSource;

/**
 TERMS:
     - view is usually used in the context only coordinate frames involved. the scope (volume)
       is infinite or indefinite.
     - scene is usually used when it is critical to know the scope (or span) of visible objects (mesh)
       occupying the space (e.g. when talking about the center or span, or near-far scope).
 */



typedef enum
{
    kTransformMode_Model,
    kTransformMode_View,
}
TransformMode;



@interface ModelRenderer : NuoMeshSceneRenderPass <NuoMeshSceneParametersProvider> 


@property (nonatomic, strong) NSArray<NuoLightSource*>* lights;
@property (nonatomic, strong) NuoCubeMesh* cubeMesh;
@property (nonatomic, strong) NuoBackdropMesh* backdropMesh;
@property (nonatomic, readonly) BOOL hasMeshes;


@property (nonatomic, assign) TransformMode transMode;
@property (nonatomic, readonly) BOOL viewTransformReset;

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


@property (nonatomic, assign) BOOL cullEnabled;
@property (nonatomic, assign) float fieldOfView;
@property (nonatomic, assign) float ambientDensity;

@property (nonatomic, strong, readonly) NuoMeshOption* modelOptions;
@property (nonatomic, assign) NuoDeferredRenderUniforms deferredParameters;


- (instancetype)initWithDevice:(id<MTLDevice>)device;

- (void)loadMesh:(NSString*)path withCommandQueue:(id<MTLCommandQueue>)commandQueue
                                    withProgress:(NuoProgressFunction)progress;
- (BOOL)loadPackage:(NSString*)path withCommandQueue:(id<MTLCommandQueue>)commandQueue
                                    withProgress:(NuoProgressFunction)progress;
- (BOOL)isValidPack:(NSString*)path;

- (NuoMeshCompound*)mainModelMesh;

- (NSString*)exportSceneAsString:(CGSize)canvasSize;
- (void)importScene:(NuoLua*)lua;

- (void)setModelOptions:(NuoMeshOption*)modelOptions
       withCommandQueue:(id<MTLCommandQueue>)commandQueue
           withProgress:(NuoProgressFunction)progress;

- (NuoBoardMesh*)createBoard:(CGSize)size;
- (void)resetViewTransform;
- (void)removeSelectedMesh;
- (void)selectMeshWithScreen:(CGPoint)point;

- (NSArray<NuoMesh*>*)cloneMeshesFor:(NuoMeshModeShaderParameter)mode;


@end
