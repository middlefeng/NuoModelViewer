

#import "NuoMeshSceneRenderPass.h"


@class NuoMeshSceneRoot;
@class ModelRenderer;


@interface ModelDissectRenderer : NuoMeshSceneRenderPass


@property (nonatomic, strong) NuoMeshSceneRoot* dissectScene;
@property (nonatomic, assign) float splitViewProportion;


- (instancetype)initWithCommandQueue:(id<MTLCommandQueue>)commandQueue;
- (void)setSampleCount:(NSUInteger)sampleCount;


@end
