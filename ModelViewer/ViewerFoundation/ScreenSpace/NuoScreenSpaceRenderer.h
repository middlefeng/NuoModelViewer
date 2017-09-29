//
//  NuoScreenSpaceRenderer.h
//  ModelViewer
//
//  Created by Dong on 9/28/17.
//  Copyright © 2017 middleware. All rights reserved.
//

#import "NuoRenderPass.h"


@class NuoMesh;


@interface NuoScreenSpaceRenderer : NuoRenderPass


/**
 *  Scene model. Be weak reference because the owner should be the model render.
 */
@property (nonatomic, weak) NSArray<NuoMesh*>* meshes;


@end
