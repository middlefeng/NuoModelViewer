//
//  ShadowMapRenderer.h
//  ModelViewer
//
//  Created by middleware on 1/16/17.
//  Copyright © 2017 middleware. All rights reserved.
//



#import <Foundation/Foundation.h>
#import "NuoRenderPass.h"


@class LightSource;
@class NuoMesh;
@class NuoShadowMapTarget;


@interface ShadowMapRenderer : NuoRenderPass


@property (nonatomic, weak) LightSource* lightSource;
@property (nonatomic, weak) NSArray<NuoMesh*>* mesh;

@property (nonatomic, strong) NuoShadowMapTarget* shadowMap;


@end
