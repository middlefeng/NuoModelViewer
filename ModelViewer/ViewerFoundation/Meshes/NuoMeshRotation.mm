//
//  NuoMeshRotation.m
//  ModelViewer
//
//  Created by middleware on 2/2/17.
//  Copyright © 2017 middleware. All rights reserved.
//

#import "NuoMeshRotation.h"



@implementation NuoMeshRotation
{
    NuoMatrixFloat44 _rotationMatrix;
}


- (instancetype)init
{
    self = [super init];
    
    if (self)
    {
        _x = 0;
        _y = 0;
        _z = 0;
        _xAxis = 0;
        _yAxis = 0;
        _zAxis = 1;
        _radius = 0;
    }
    
    [self generateMatrices];
    
    return self;
}



- (instancetype)initWith:(NuoMeshRotation*)rotation
{
    self = [super init];
    
    if (self)
    {
        _x = rotation.x;
        _y = rotation.y;
        _z = rotation.z;
        _xAxis = rotation.xAxis;
        _yAxis = rotation.yAxis;
        _zAxis = rotation.zAxis;
        _radius = rotation.radius;
    }
    
    [self generateMatrices];
    
    return self;
}


- (void)generateMatrices
{
    NuoVectorFloat3 transformVector( _x, _y, _z);
    NuoVectorFloat3 rotationVector(_xAxis, _yAxis, _zAxis);
    
    NuoMatrixFloat44 transMatrix = NuoMatrixTranslation(transformVector);
    NuoMatrixFloat44 transMatrixInv = NuoMatrixTranslation(-transformVector);
    NuoMatrixFloat44 rotationMatrix = NuoMatrixRotation(rotationVector.Normalize(), _radius);
    
    _rotationMatrix = (transMatrixInv * (rotationMatrix * transMatrix));
}



- (void)setRadius:(float)radius
{
    _radius = radius;
    [self generateMatrices];
}



- (const NuoMatrixFloat44&)rotationMatrix
{
    return _rotationMatrix;
}


@end
