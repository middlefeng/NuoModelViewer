//
//  NuoScreenSpaceRenderer.m
//  ModelViewer
//
//  Created by Dong on 9/28/17.
//  Copyright © 2017 middleware. All rights reserved.
//

#import "NuoScreenSpaceRenderer.h"
#import "NuoScreenSpaceTarget.h"



@implementation NuoScreenSpaceRenderer


- (instancetype)initWithDevice:(id<MTLDevice>)device withName:(NSString*)name
{
    self = [super init];
    
    if (self)
    {
        self.renderTarget = [[NuoScreenSpaceTarget alloc] init];
        self.renderTarget.device = device;
        self.device = device;
    }
    
    return self;
}


@end
