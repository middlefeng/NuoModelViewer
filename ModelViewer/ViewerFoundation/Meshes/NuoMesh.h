
#import <Metal/Metal.h>

#include <memory>



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
@property (nonatomic, strong) id<MTLDepthStencilState> depthStencilState;


@property (nonatomic, readonly) id<MTLBuffer> vertexBuffer;
@property (nonatomic, readonly) id<MTLBuffer> indexBuffer;

@property (nonatomic, strong) NuoMeshBox* boundingBox;


- (instancetype)initWithDevice:(id<MTLDevice>)device
            withVerticesBuffer:(void*)buffer withLength:(size_t)length
                   withIndices:(void*)indices withLength:(size_t)indicesLength;


- (void)drawMesh:(id<MTLRenderCommandEncoder>)renderPass;


@end




@interface NuoMeshTextured : NuoMesh


@property (nonatomic, readonly) id<MTLTexture> diffuseTex;
@property (nonatomic, readonly) id<MTLSamplerState> samplerState;


- (instancetype)initWithDevice:(id<MTLDevice>)device
               withTexutrePath:(NSString*)texPath
            withVerticesBuffer:(void*)buffer withLength:(size_t)length
                   withIndices:(void*)indices withLength:(size_t)indicesLength;


@end




class NuoModelBase;

NuoMesh* CreateMesh(NSString* type,
                    id<MTLDevice> device,
                    const std::shared_ptr<NuoModelBase> model);


