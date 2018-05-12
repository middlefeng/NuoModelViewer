//
//  NuoMeshRotation.h
//  ModelViewer
//
//  Created by middleware on 2/2/17.
//  Copyright © 2017 middleware. All rights reserved.
//

#import <Foundation/Foundation.h>

#include "NuoMathVector.h"


@interface NuoMeshRotation : NSObject

@property (nonatomic, assign) float x;
@property (nonatomic, assign) float y;
@property (nonatomic, assign) float z;

@property (nonatomic, assign) float xAxis;
@property (nonatomic, assign) float yAxis;
@property (nonatomic, assign) float zAxis;

@property (nonatomic, assign) float radius;

- (instancetype)initWith:(NuoMeshRotation*)rotation;

- (const NuoMatrixFloat44&)rotationMatrix;

@end
