//
//  NuoBoardMesh.m
//  ModelViewer
//
//  Created by middleware on 6/7/17.
//  Copyright © 2017 middleware. All rights reserved.
//

#import "NuoBoardMesh.h"
#include "NuoModelBoard.h"



@interface NuoBoardMesh()

- (instancetype)initWithDevice:(id<MTLDevice>)device
            withVerticesBuffer:(void *)buffer withLength:(size_t)length
                   withIndices:(void *)indices withLength:(size_t)indicesLength
                 withDimension:(NuoCoord*)coord;

@end



NuoBoardMesh* CreateBoardMesh(id<MTLDevice> device, const std::shared_ptr<NuoModelBoard> model, bool shadowCastOnly)
{
    NuoBoardMesh* resultMesh = nil;
    NuoCoord* dimensions = [NuoCoord new];
    dimensions.x = model->_width;
    dimensions.y = model->_height;
    dimensions.z = model->_thickness;
    
    resultMesh = [[NuoBoardMesh alloc] initWithDevice:device
                                   withVerticesBuffer:model->Ptr()
                                           withLength:model->Length()
                                          withIndices:model->IndicesPtr()
                                           withLength:model->IndicesLength()
                                        withDimension:dimensions];
    
    NuoBox boundingBox = model->GetBoundingBox();
    
    NuoMeshBox* meshBounding = [[NuoMeshBox alloc] init];
    meshBounding.span.x = boundingBox._spanX;
    meshBounding.span.y = boundingBox._spanY;
    meshBounding.span.z = boundingBox._spanZ;
    meshBounding.center.x = boundingBox._centerX;
    meshBounding.center.y = boundingBox._centerY;
    meshBounding.center.z = boundingBox._centerZ;
    
    resultMesh.boundingBoxLocal = meshBounding;
    
    [resultMesh setShadowOverlayOnly:shadowCastOnly];
    
    [resultMesh makePipelineShadowState];
    [resultMesh makePipelineState:[resultMesh makePipelineStateDescriptor]];
    [resultMesh makeDepthStencilState];
    
    [resultMesh setRawModel:model.get()];
    
    return resultMesh;
}
