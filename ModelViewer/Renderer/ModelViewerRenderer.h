
#import "ModelView.h"
#import "NuoRenderPipelinePass.h"

#import <simd/simd.h>


@class NuoMeshOption;
@class NuoLua;
@class NuoMesh;
@class LightSource;



@interface ModelRenderer : NuoRenderPipelinePass


@property (nonatomic, strong) NSArray<LightSource*>* lights;


@property (nonatomic, assign) float zoom;


@property (nonatomic, assign) float rotationXDelta;
@property (nonatomic, assign) float rotationYDelta;

@property (nonatomic, assign) float transX;
@property (nonatomic, assign) float transY;

@property (nonatomic, assign) BOOL cullEnabled;
@property (nonatomic, assign) float fieldOfView;
@property (nonatomic, assign) float ambientDensity;

@property (nonatomic, strong) NuoMeshOption* modelOptions;


- (instancetype)initWithDevice:(id<MTLDevice>)device;

/**
 *  The rotation matrix of the model, which is culmulated from all the delta of X and Y.
 */
- (matrix_float4x4)rotationMatrix;

- (void)loadMesh:(NSString*)path;
- (NSArray<NuoMesh*>*)mesh;

- (NSString*)exportSceneAsString:(CGSize)canvasSize;
- (void)importScene:(NuoLua*)lua;


@end
