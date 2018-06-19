//
//  NuoRayTracingAccelerateStructure.h
//  ModelViewer
//
//  Created by middleware on 6/16/18.
//  Copyright © 2018 middleware. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <Metal/Metal.h>

#include "NuoMathVector.h"


@class NuoMesh;
@class NuoRenderPassTarget;


@interface NuoRayAccelerateStructure : NSObject


@property (nonatomic, assign) CGFloat fieldOfView;
@property (nonatomic, assign) CGSize drawableSize;


- (instancetype)initWithQueue:(id<MTLCommandQueue>)queue;

- (void)setMeshes:(NSArray<NuoMesh*>*)meshes withView:(const NuoMatrixFloat44&)viewTrans;
- (void)rayTrace:(id<MTLCommandBuffer>)commandBuffer inFlight:(uint32_t)inFlight
        toTarget:(NuoRenderPassTarget*)renderTarget;



@end


