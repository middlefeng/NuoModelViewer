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
    {
        _shadowOccluderRadius = 5.0f;
        _shadowOccluderSampleCount = 3;
    }
    
    return self;
}

@end
