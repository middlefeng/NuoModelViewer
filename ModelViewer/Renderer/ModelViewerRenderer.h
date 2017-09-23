
#import "ModelView.h"

#import "NuoUniforms.h"
#import "NuoRenderPipelinePass.h"


@class NuoMesh;
@class NuoMeshOption;
@class NuoLua;
@class NuoMeshCompound;
@class NuoBoardMesh;
@class NuoCubeMesh;
@class NuoLightSource;


typedef enum
{
    kTransformMode_Model,
    kTransformMode_View,
}
TransformMode;



@interface ModelRenderer : NuoRenderPipelinePass


@property (nonatomic, strong) NSArray<NuoLightSource*>* lights;
@property (nonatomic, strong) NuoCubeMesh* cubeMesh;


@property (nonatomic, assign) TransformMode transMode;

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


- (instancetype)initWithDevice:(id<MTLDevice>)device;

- (void)loadMesh:(NSString*)path withCommandQueue:(id<MTLCommandQueue>)commandQueue;
- (NuoMeshCompound*)mainModelMesh;

- (NSString*)exportSceneAsString:(CGSize)canvasSize;
- (void)importScene:(NuoLua*)lua;

- (void)setModelOptions:(NuoMeshOption*)modelOptions
       withCommandQueue:(id<MTLCommandQueue>)commandQueue;

- (NuoBoardMesh*)createBoard:(CGSize)size;
- (void)selectMeshWithScreen:(CGPoint)point;

// there might be other renderers share the same set of meshes/scene with the model renderer.
// one example is the model dissect renderer. the following methods are used for the state-sharing
//
- (void)setSceneBuffersTo:(id<MTLRenderCommandEncoder>)renderPass withInFlightIndex:(unsigned int)inFlight;
- (NSArray<NuoMesh*>*)cloneMeshesFor:(NuoMeshModeShaderParameter)mode;


@end
