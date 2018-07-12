//
//  NuoScreenSpaceRenderer.h
//  ModelViewer
//
//  Created by Dong on 9/28/17.
//  Copyright © 2017 middleware. All rights reserved.
//

#import "NuoMeshSceneRenderPass.h"


@class NuoMeshSceneRoot;


@interface NuoScreenSpaceRenderer : NuoMeshSceneRenderPass


/**
 *  Scene model. Be weak reference because the owner should be the model render.
 */
@property (nonatomic, weak) NuoMeshSceneRoot* sceneRoot;

@property (nonatomic, readonly) id<MTLTexture> positionBuffer;
@property (nonatomic, readonly) id<MTLTexture> normalBuffer;
@property (nonatomic, readonly) id<MTLTexture> ambientBuffer;
@property (nonatomic, readonly) id<MTLTexture> shdowOverlayBuffer;

- (instancetype)initWithCommandQueue:(id<MTLCommandQueue>)commandQueue withName:(NSString*)name;


@end
