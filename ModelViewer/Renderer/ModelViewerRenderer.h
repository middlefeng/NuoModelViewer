
#import "ModelView.h"
#import "NuoRenderPipelinePass.h"


@class NuoMeshOption;
@class NuoLua;
@class NuoMeshCompound;
@class NuoCubeMesh;
@class NuoLightSource;



@interface ModelRenderer : NuoRenderPipelinePass


@property (nonatomic, strong) NSArray<NuoLightSource*>* lights;
@property (nonatomic, strong) NuoCubeMesh* cubeMesh;


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

- (void)createBoard:(CGSize)size;
- (void)createBoardWithImage:(NSString*)path;
- (void)selectMeshWithScreen:(CGPoint)point;


@end
