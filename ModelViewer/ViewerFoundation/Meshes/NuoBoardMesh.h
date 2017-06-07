//
//  NuoBoardMesh.h
//  ModelViewer
//
//  Created by middleware on 6/6/17.
//  Copyright © 2017 middleware. All rights reserved.
//

#import "NuoMesh.h"


@interface NuoBoardMesh : NuoMesh

- (MTLRenderPipelineDescriptor*)makePipelineStateDescriptor;

@end



#if __cplusplus

#include <memory>


class NuoModelBoard;

NuoBoardMesh* CreateMesh(id<MTLDevice> device, const std::shared_ptr<NuoModelBoard> model);

#endif
