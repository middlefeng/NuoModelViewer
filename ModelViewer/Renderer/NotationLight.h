//
//  NotationLight.h
//  ModelViewer
//
//  Created by middleware on 11/13/16.
//  Copyright © 2016 middleware. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <Metal/Metal.h>

#include "NuoMeshBounds.h"


@class NuoLightSource;
@class NuoRenderPassEncoder;


@interface NotationLight : NSObject


@property (nonatomic, weak) NuoLightSource* lightSourceDesc;

@property (nonatomic, assign) BOOL selected;


- (instancetype)initWithCommandQueue:(id<MTLCommandQueue>)commandQueue isBold:(BOOL)bold;

- (void)drawWithRenderPass:(NuoRenderPassEncoder*)renderPass;


- (NuoMeshBounds)bounds;
- (CGPoint)headPointProjectedWithView:(const NuoMatrixFloat44&)view;


@end
