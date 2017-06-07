//
//  NuoBoardMesh.m
//  ModelViewer
//
//  Created by middleware on 6/7/17.
//  Copyright © 2017 middleware. All rights reserved.
//

#import "NuoBoardMesh.h"
#include "NuoModelBoard.h"


NuoBoardMesh* CreateMesh(id<MTLDevice> device, const std::shared_ptr<NuoModelBoard> model)
{
    NuoBoardMesh* resultMesh = nil;
    
    resultMesh = [[NuoBoardMesh alloc] initWithDevice:device
                                   withVerticesBuffer:model->Ptr()
                                           withLength:model->Length()
                                          withIndices:model->IndicesPtr()
                                           withLength:model->IndicesLength()];
    
    return resultMesh;
}
