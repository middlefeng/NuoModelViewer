//
//  NuoLightSource.m
//  ModelViewer
//
//  Created by middleware on 11/19/16.
//  Copyright © 2016 middleware. All rights reserved.
//

#import "NuoLightSource.h"


@implementation NuoLightSource


- (instancetype)init
{
    self = [super init];
    if (self)
        _lightDirection = NuoMatrixFloat44Identity;
    
    return self;
}


@end
