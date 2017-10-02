//
//  NuoAmbientOcclusionRenderer.h
//  ModelViewer
//
//  Created by Dong on 10/1/17.
//  Copyright © 2017 middleware. All rights reserved.
//

#import "NuoRenderPass.h"


@protocol NuoMeshSceneParametersProvider;
@class NuoMesh;


@interface NuoDeferredRenderer : NuoRenderPass


- (instancetype)initWithDevice:(id<MTLDevice>)device
            withSceneParameter:(id<NuoMeshSceneParametersProvider>)sceneParameter;

- (void)setMeshes:(NSArray<NuoMesh*>*)meshes;


@end
