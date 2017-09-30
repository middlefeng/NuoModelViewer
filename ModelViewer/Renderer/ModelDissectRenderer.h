

#import "NuoMeshSceneRenderPass.h"


@class NuoMesh;
@class ModelRenderer;


@interface ModelDissectRenderer : NuoMeshSceneRenderPass


@property (nonatomic, strong) NSArray<NuoMesh*>* dissectMeshes;
@property (nonatomic, assign) float splitViewProportion;


- (instancetype)initWithDevice:(id<MTLDevice>)device;


@end
