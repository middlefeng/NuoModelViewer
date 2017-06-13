//
//  NuoBoardMesh.m
//  ModelViewer
//
//  Created by middleware on 6/7/17.
//  Copyright © 2017 middleware. All rights reserved.
//

#import "NuoBoardMesh.h"
#import "NuoTextureBase.h"

#include <memory>
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
    
    resultMesh.boundingBoxLocal = meshBounding;
    resultMesh.shadowCasted = YES;
    
    [resultMesh makePipelineShadowState];
    [resultMesh makePipelineState:[resultMesh makePipelineStateDescriptor]];
    [resultMesh makeDepthStencilState];
    
    return resultMesh;
}



NuoBoardMesh* CreateBoardMeshWithTexture(id<MTLDevice> device, NSString* texPath)
{
    NuoTextureBase* base = [NuoTextureBase getInstance:device];
    NuoTexture* texture = [base texture2DWithImageNamed:texPath mipmapped:NO checkTransparency:NO commandQueue:nil];
    
    float width = texture.texture.width;
    float height = texture.texture.height;
    float aspectRatio = width / height;
    
    float modelHeight = 100;
    float modelWidth = modelHeight * aspectRatio;
    
    std::shared_ptr<NuoModelBoard> model(new NuoModelBoard(modelWidth, modelHeight, 0.001));
    model->CreateBuffer();
    
    NuoBoardMesh* resultMesh = [[NuoBoardMesh alloc] initWithDevice:device
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
    
    resultMesh.boundingBoxLocal = meshBounding;
    resultMesh.shadowCasted = NO;
    resultMesh.image = texture.texture;
    
    [resultMesh makePipelineShadowState];
    [resultMesh makePipelineState:[resultMesh makePipelineStateDescriptor]];
    [resultMesh makeDepthStencilState];
    
    return resultMesh;
}


