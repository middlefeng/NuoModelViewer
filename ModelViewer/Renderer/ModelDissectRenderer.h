

#import "NuoRenderPipelinePass.h"


@class NuoMesh;
@class ModelRenderer;


@interface ModelDissectRenderer : NuoRenderPipelinePass


@property (nonatomic, strong) NSArray<NuoMesh*>* dissectMeshes;
@property (nonatomic, weak) ModelRenderer* modelRenderer;

@property (nonatomic, assign) float splitViewProportion;


- (instancetype)initWithDevice:(id<MTLDevice>)device;


@end
