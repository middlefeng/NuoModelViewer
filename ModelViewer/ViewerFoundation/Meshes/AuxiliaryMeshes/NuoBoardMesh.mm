//
//  NuoBoardMesh.m
//  ModelViewer
//
//  Created by middleware on 6/6/17.
//  Copyright © 2017 middleware. All rights reserved.
//

#import "NuoBoardMesh.h"
#import "NuoMesh_Extension.h"

#import "NuoMeshBounds.h"
#include "NuoModelBoard.h"



@implementation NuoBoardMesh
{
    NuoVectorFloat3 _dimensions;
}



- (instancetype)initWithCommandQueue:(id<MTLCommandQueue>)commandQueue
                  withVerticesBuffer:(void *)buffer withLength:(size_t)length
                         withIndices:(void *)indices withLength:(size_t)indicesLength
                       withDimension:(const NuoVectorFloat3&)dimensions
{
    self = [super initWithCommandQueue:commandQueue
                    withVerticesBuffer:buffer withLength:length
                           withIndices:indices withLength:indicesLength];
    
    if (self)
    {
        _dimensions = dimensions;
    }
    
    return self;
}



- (instancetype)cloneForMode:(NuoMeshModeShaderParameter)mode
{
    NuoBoardMesh* boardMesh = [NuoBoardMesh new];
    [boardMesh shareResourcesFrom:self];
    
    boardMesh.meshMode = mode;
    
    [boardMesh makePipelineShadowState];
    [boardMesh makePipelineState:[boardMesh makePipelineStateDescriptor]];
    [boardMesh makeDepthStencilState];
    
    return boardMesh;
}



- (MTLRenderPipelineDescriptor*)makePipelineStateDescriptor
{
    id<MTLLibrary> library = [self library];
    
    NSString* vertexFunc = @"vertex_project_shadow";
    NSString* fragmnFunc = @"fragment_light_shadow";
    
    // board mesh has no specular factor
    BOOL physicallyReflection = NO;
    
    MTLFunctionConstantValues* funcConstant = [MTLFunctionConstantValues new];
    [funcConstant setConstantValue:&physicallyReflection type:MTLDataTypeBool atIndex:2];
    [funcConstant setConstantValue:&_shadowOverlayOnly type:MTLDataTypeBool atIndex:3];
    [self setupCommonPipelineFunctionConstants:funcConstant];
    
    MTLRenderPipelineDescriptor *pipelineDescriptor = [MTLRenderPipelineDescriptor new];
    pipelineDescriptor.vertexFunction = [library newFunctionWithName:vertexFunc];
    pipelineDescriptor.fragmentFunction = [library newFunctionWithName:fragmnFunc
                                                        constantValues:funcConstant error:nil];
    pipelineDescriptor.rasterSampleCount = self.sampleCount;
    pipelineDescriptor.colorAttachments[0].pixelFormat = MTLPixelFormatRGBA16Float;
    pipelineDescriptor.depthAttachmentPixelFormat = MTLPixelFormatDepth32Float;
    
    MTLRenderPipelineColorAttachmentDescriptor* colorAttachment = pipelineDescriptor.colorAttachments[0];
    [self applyTransmissionBlending:colorAttachment];
    
    return pipelineDescriptor;
}

- (void)makePipelineShadowState
{
    [super makePipelineShadowState:@"vertex_simple"];
}


- (void)makePipelineScreenSpaceState
{
    MTLFunctionConstantValues* constants = [MTLFunctionConstantValues new];
    BOOL shadowOverlay = self.shadowOverlayOnly;
    BOOL rayTracing = self.shadowOptionRayTracing;
    [constants setConstantValue:&shadowOverlay type:MTLDataTypeBool atIndex:3];
    [constants setConstantValue:&rayTracing type:MTLDataTypeBool atIndex:7];
    
    [super makePipelineScreenSpaceStateWithVertexShader:@"vertex_project_screen_space"
                                     withFragemtnShader:@"fragement_screen_space"
                                          withConstants:constants];
}


- (void)drawMesh:(NuoRenderPassEncoder*)renderPass
{
    [renderPass pushParameterState:@"Board mesh"];
    
    [renderPass setCullMode:MTLCullModeBack];
    [super drawMesh:renderPass];
    
    [renderPass popParameterState];
}


- (const NuoVectorFloat3&)dimensions
{
    return _dimensions;
}


- (std::vector<NuoRayMask>)maskBuffer
{
    std::vector<NuoRayMask> oneBuffer = [super maskBuffer];
    
    if (self.shadowOverlayOnly)
    {
        for (NuoRayMask& item : oneBuffer)
            item = kNuoRayMask_Virtual;
    }
    
    return oneBuffer;
}


- (NSColor*)diffuse
{
    NuoModelBoard* boardModel = dynamic_cast<NuoModelBoard*>(self.rawModel.get());
    
    assert(boardModel != nullptr);
    
    const NuoVectorFloat3& colorVec = boardModel->GetDiffuse();
    NSColor* color = [NSColor colorWithRed:colorVec.x() green:colorVec.y() blue:colorVec.z() alpha:1.0];
    
    return color;
}


- (void)setDiffuse:(NSColor*)diffuse
{
    NuoModelBoard* boardModel = dynamic_cast<NuoModelBoard*>(self.rawModel.get());
    
    assert(boardModel != nullptr);
    
    NuoVectorFloat3 colorVec(diffuse.redComponent,
                             diffuse.greenComponent,
                             diffuse.blueComponent);
    
    boardModel->SetDiffuse(colorVec);
}


- (NSColor*)specular
{
    NuoModelBoard* boardModel = dynamic_cast<NuoModelBoard*>(self.rawModel.get());
    
    assert(boardModel != nullptr);
    
    const NuoVectorFloat3& colorVec = boardModel->GetSpecular();
    NSColor* color = [NSColor colorWithRed:colorVec.x() green:colorVec.y() blue:colorVec.z() alpha:1.0];
    
    return color;
}


- (void)setSpecular:(NSColor*)specular
{
    NuoModelBoard* boardModel = dynamic_cast<NuoModelBoard*>(self.rawModel.get());
    
    assert(boardModel != nullptr);
    
    NuoVectorFloat3 colorVec(specular.redComponent,
                             specular.greenComponent,
                             specular.blueComponent);
    
    boardModel->SetSpecular(colorVec);
}


- (float)specularPower
{
    NuoModelBoard* boardModel = dynamic_cast<NuoModelBoard*>(self.rawModel.get());
    
    assert(boardModel != nullptr);
    return boardModel->GetSpecularPower();
}


- (void)setSpecularPower:(float)specularPower
{
    NuoModelBoard* boardModel = dynamic_cast<NuoModelBoard*>(self.rawModel.get());
    
    assert(boardModel != nullptr);
    boardModel->SetSpecularPower(specularPower);
}


@end



NuoBoardMesh* CreateBoardMesh(id<MTLCommandQueue> commandQueue, const std::shared_ptr<NuoModelBoard> model, bool shadowCastOnly)
{
    NuoBoardMesh* resultMesh = nil;
    
    resultMesh = [[NuoBoardMesh alloc] initWithCommandQueue:commandQueue
                                         withVerticesBuffer:model->Ptr()
                                                 withLength:model->Length()
                                                withIndices:model->IndicesPtr()
                                                 withLength:model->IndicesLength()
                                              withDimension:NuoVectorFloat3(model->_width, model->_height, model->_thickness)];
    
    NuoMeshBounds bounds;
    bounds.boundingBox = model->GetBoundingBox();
    
    resultMesh.boundsLocal = bounds;
    
    [resultMesh setRawModel:model];
    [resultMesh setShadowOverlayOnly:shadowCastOnly];
    [resultMesh makeGPUStates];
    
    return resultMesh;
}
