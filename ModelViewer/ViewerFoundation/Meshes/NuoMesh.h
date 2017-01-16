
#import <Metal/Metal.h>

#include "NuoMeshOptions.h"



@interface NuoMeshBox : NSObject

@property (nonatomic, assign) float centerX;
@property (nonatomic, assign) float centerY;
@property (nonatomic, assign) float centerZ;

@property (nonatomic, assign) float spanX;
@property (nonatomic, assign) float spanY;
@property (nonatomic, assign) float spanZ;

- (NuoMeshBox*)unionWith:(NuoMeshBox*)other;

@end



@interface NuoMesh : NSObject

@property (nonatomic, strong) id<MTLDevice> device;
@property (nonatomic, strong) id<MTLRenderPipelineState> renderPipelineState;
@property (nonatomic, strong) id<MTLRenderPipelineState> shadowPipelineState;
@property (nonatomic, strong) id<MTLDepthStencilState> depthStencilState;

@property (nonatomic, readonly, assign) float smoothTolerance;


@property (nonatomic, readonly) id<MTLBuffer> vertexBuffer;
@property (nonatomic, readonly) id<MTLBuffer> indexBuffer;

@property (nonatomic, strong) NuoMeshBox* boundingBox;
@property (nonatomic, assign) BOOL enabled;


- (instancetype)initWithDevice:(id<MTLDevice>)device
            withVerticesBuffer:(void*)buffer withLength:(size_t)length
                   withIndices:(void*)indices withLength:(size_t)indicesLength;

- (MTLRenderPipelineDescriptor*)makePipelineStateDescriptor;
- (void)makePipelineState:(MTLRenderPipelineDescriptor*)pipelineDescriptor;
- (void)makeDepthStencilState;


- (void)setRawModel:(void*)model;
- (NSString*)modelName;
- (void)smoothWithTolerance:(float)tolerance;


- (void)drawMesh:(id<MTLRenderCommandEncoder>)renderPass;
- (void)drawShadow:(id<MTLRenderCommandEncoder>)renderPass;
- (BOOL)hasTransparency;
- (void)setTransparency:(BOOL)transparent;


@end


#if __cplusplus

#include <memory>


class NuoModelBase;
class NuoModelOption;

NuoMesh* CreateMesh(const NuoModelOption& options,
                    id<MTLDevice> device,
                    const std::shared_ptr<NuoModelBase> model);

#endif


