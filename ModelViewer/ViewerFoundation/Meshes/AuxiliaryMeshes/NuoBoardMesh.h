//
//  NuoBoardMesh.h
//  ModelViewer
//
//  Created by middleware on 6/6/17.
//  Copyright © 2017 middleware. All rights reserved.
//

#import "NuoMesh.h"
#import "NuoConfiguration.h"


@interface NuoBoardMesh : NuoMesh

@property (assign, readonly) const NuoVectorFloat3& dimensions;
@property (assign, nonatomic) BOOL shadowOverlayOnly;
@property (strong, nonatomic) NuoColor* diffuse;
@property (strong, nonatomic) NuoColor* specular;
@property (assign, nonatomic) float specularPower;

- (MTLRenderPipelineDescriptor*)makePipelineStateDescriptor;
- (void)makePipelineShadowState;
- (void)makePipelineScreenSpaceState;

@end



#if __cplusplus

#include <memory>
#include "NuoModelBoard.h"


NuoBoardMesh* CreateBoardMesh(id<MTLCommandQueue> commandQueue, const std::shared_ptr<NuoModelBoard> model, bool shadowCastOnly);

#endif
