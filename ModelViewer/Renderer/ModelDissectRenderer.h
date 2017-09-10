

#import "NuoIntermediateRenderPass.h"


@class NuoMesh;
@class ModelRenderer;


@interface ModelDissectRenderer : NuoIntermediateRenderPass


@property (nonatomic, strong) NSArray<NuoMesh*>* dissectMeshes;
@property (nonatomic, weak) ModelRenderer* modelRenderer;


- (instancetype)initWithDevice:(id<MTLDevice>)device;


@end
