//
//  NuoMesh_Extension.h
//  ModelViewer
//
//  Created by Dong on 4/28/18.
//  Copyright © 2018 middleware. All rights reserved.
//


// Do NOT include the NuoMesh as the subclass should have it


@interface NuoMesh (Extension)


// used to implement the "cloneForMode" through the class hierachy
//
- (void)shareResourcesFrom:(NuoMesh*)mesh;
- (void)setMeshMode:(NuoMeshModeShaderParameter)mode;
- (NuoMeshModeShaderParameter)meshMode;

//
// pipeline construction facilities
//

- (MTLRenderPipelineDescriptor*)makePipelineStateDescriptor;
- (void)makePipelineState:(MTLRenderPipelineDescriptor*)pipelineDescriptor;
- (void)makePipelineShadowState:(NSString*)vertexShadowShader;

- (void)makePipelineScreenSpaceStateWithVertexShader:(NSString*)vertexShader
                                  withFragemtnShader:(NSString*)fragmentShader;
- (void)makePipelineScreenSpaceStateWithVertexShader:(NSString*)vertexShader
                                  withFragemtnShader:(NSString*)fragmentShader
                                       withConstants:(MTLFunctionConstantValues*)constants;

- (void)setupCommonPipelineFunctionConstants:(MTLFunctionConstantValues*)constants;


@end
