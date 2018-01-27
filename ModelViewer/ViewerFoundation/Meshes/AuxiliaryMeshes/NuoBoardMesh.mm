//
//  NuoBoardMesh.m
//  ModelViewer
//
//  Created by middleware on 6/7/17.
//  Copyright © 2017 middleware. All rights reserved.
//

#import "NuoBoardMesh.h"
#import "NuoMeshBounds.h"

#include "NuoModelBoard.h"



@interface NuoBoardMesh()

- (instancetype)initWithDevice:(id<MTLDevice>)device
            withVerticesBuffer:(void *)buffer withLength:(size_t)length
                   withIndices:(void *)indices withLength:(size_t)indicesLength
                 withDimension:(vector_float3)dimension;

@end



NuoBoardMesh* CreateBoardMesh(id<MTLDevice> device, const std::shared_ptr<NuoModelBoard> model, bool shadowCastOnly)
{
    NuoBoardMesh* resultMesh = nil;
    vector_float3 dimensions = { model->_width, model->_height, model->_thickness };
    
    resultMesh = [[NuoBoardMesh alloc] initWithDevice:device
                                   withVerticesBuffer:model->Ptr()
                                           withLength:model->Length()
                                          withIndices:model->IndicesPtr()
                                           withLength:model->IndicesLength()
                                        withDimension:dimensions];
    
    NuoMeshBounds* bounds = [NuoMeshBounds new];
    *((NuoBounds*)[bounds boundingBox]) = model->GetBoundingBox();
    
    resultMesh.boundsLocal = bounds;
    
    [resultMesh setShadowOverlayOnly:shadowCastOnly];
    [resultMesh makePipelineShadowState];
    [resultMesh makePipelineScreenSpaceState];
    [resultMesh makePipelineState:[resultMesh makePipelineStateDescriptor]];
    [resultMesh makeDepthStencilState];
    
    return resultMesh;
}
