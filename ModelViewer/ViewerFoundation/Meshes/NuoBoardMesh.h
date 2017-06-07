//
//  NuoBoardMesh.h
//  ModelViewer
//
//  Created by middleware on 6/6/17.
//  Copyright © 2017 middleware. All rights reserved.
//

#import "NuoMesh.h"


@interface NuoBoardMesh : NuoMesh

- (instancetype)initWithDevice:(id<MTLDevice>)device
            withVerticesBuffer:(void*)buffer withLength:(size_t)length
                   withIndices:(void*)indices withLength:(size_t)indicesLength;

- (MTLRenderPipelineDescriptor*)makePipelineStateDescriptor;

@end



#if __cplusplus

#include <memory>


class NuoModelBoard;

NuoBoardMesh* CreateMesh(const std::shared_ptr<NuoModelBoard> model);

#endif
