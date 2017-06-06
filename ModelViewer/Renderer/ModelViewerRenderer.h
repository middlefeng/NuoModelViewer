
#import "ModelView.h"
#import "NuoRenderPipelinePass.h"


@class NuoMeshOption;
@class NuoLua;
@class NuoMeshCompound;
@class NuoCubeMesh;
@class LightSource;



@interface ModelRenderer : NuoRenderPipelinePass


@property (nonatomic, strong) NSArray<LightSource*>* lights;
@property (nonatomic, strong) NuoCubeMesh* cubeMesh;


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
- (NuoMeshCompound*)mesh;

- (NSString*)exportSceneAsString:(CGSize)canvasSize;
- (void)importScene:(NuoLua*)lua;

- (void)setModelOptions:(NuoMeshOption*)modelOptions
       withCommandQueue:(id<MTLCommandQueue>)commandQueue;


@end
