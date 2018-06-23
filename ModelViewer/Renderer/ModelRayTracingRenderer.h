//
//  ModelRayTracingRenderer.h
//  ModelViewer
//
//  Created by middleware on 6/22/18.
//  Copyright © 2018 middleware. All rights reserved.
//

#import "NuoRayTracingRenderer.h"

#include "NuoMathVector.h"


@protocol NuoMeshSceneParametersProvider;


@interface ModelRayTracingRenderer : NuoRayTracingRenderer

@property (nonatomic, weak) id<NuoMeshSceneParametersProvider> paramsProvider;


@end


