
#import "ModelView.h"
#import "NuoRenderPass.h"


@class NuoMeshOption;
@class LightSource;



@interface ModelRenderer : NuoRenderPass


@property (nonatomic, strong) LightSource* lights;


@property (nonatomic, assign) float zoom;


@property (nonatomic, assign) float rotationXDelta;
@property (nonatomic, assign) float rotationYDelta;

@property (nonatomic, assign) float transX;
@property (nonatomic, assign) float transY;

@property (nonatomic, assign) BOOL cullEnabled;
@property (nonatomic, assign) float fieldOfView;

@property (nonatomic, strong) NuoMeshOption* modelOptions;


- (instancetype)initWithDevice:(id<MTLDevice>)device;


- (void)loadMesh:(NSString*)path;


@end
