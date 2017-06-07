//
//  NuoBoardMesh.m
//  ModelViewer
//
//  Created by middleware on 6/7/17.
//  Copyright © 2017 middleware. All rights reserved.
//

#import "NuoBoardMesh.h"
#include "NuoModelBoard.h"


NuoBoardMesh* CreateBoardMesh(id<MTLDevice> device, const std::shared_ptr<NuoModelBoard> model)
{
    NuoBoardMesh* resultMesh = nil;
    
    resultMesh = [[NuoBoardMesh alloc] initWithDevice:device
                                   withVerticesBuffer:model->Ptr()
                                           withLength:model->Length()
                                          withIndices:model->IndicesPtr()
                                           withLength:model->IndicesLength()];
    
    NuoBox boundingBox = model->GetBoundingBox();
    
    NuoMeshBox* meshBounding = [[NuoMeshBox alloc] init];
    meshBounding.span.x = boundingBox._spanX;
    meshBounding.span.y = boundingBox._spanY;
    meshBounding.span.z = boundingBox._spanZ;
    meshBounding.center.x = boundingBox._centerX;
    meshBounding.center.y = boundingBox._centerY;
    meshBounding.center.z = boundingBox._centerZ;
    
    resultMesh.boundingBox = meshBounding;
    
    [resultMesh makePipelineShadowState];
    [resultMesh makePipelineState:[resultMesh makePipelineStateDescriptor]];
    [resultMesh makeDepthStencilState];
    
    return resultMesh;
}
