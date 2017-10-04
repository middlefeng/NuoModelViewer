//
//  NuoScreenSpaceRenderer.h
//  ModelViewer
//
//  Created by Dong on 9/28/17.
//  Copyright © 2017 middleware. All rights reserved.
//

#import "NuoMeshSceneRenderPass.h"


@class NuoMesh;


@interface NuoScreenSpaceRenderer : NuoMeshSceneRenderPass


/**
 *  Scene model. Be weak reference because the owner should be the model render.
 */
@property (nonatomic, weak) NSArray<NuoMesh*>* meshes;

@property (nonatomic, readonly) id<MTLTexture> positionBuffer;
@property (nonatomic, readonly) id<MTLTexture> normalBuffer;
@property (nonatomic, readonly) id<MTLTexture> ambientBuffer;

- (instancetype)initWithDevice:(id<MTLDevice>)device withName:(NSString*)name;


@end
