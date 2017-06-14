//
//  NuoBoardMesh.h
//  ModelViewer
//
//  Created by middleware on 6/6/17.
//  Copyright © 2017 middleware. All rights reserved.
//

#import "NuoMesh.h"


@interface NuoBoardMesh : NuoMesh

@property (assign, nonatomic) BOOL shadowOverlayOnly;

@property (readonly, nonatomic, strong) NuoCoord* dimension;

- (MTLRenderPipelineDescriptor*)makePipelineStateDescriptor;
- (void)makePipelineShadowState;

@end



#if __cplusplus

#include <memory>
#include "NuoModelBoard.h"


NuoBoardMesh* CreateBoardMesh(id<MTLDevice> device, const std::shared_ptr<NuoModelBoard> model);

#endif
