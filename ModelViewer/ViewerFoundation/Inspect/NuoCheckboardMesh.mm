//
//  NuoCheckboardMesh.m
//  ModelViewer
//
//  Created by middleware on 9/11/18.
//  Copyright © 2018 middleware. All rights reserved.
//

#import "NuoCheckboardMesh.h"

@implementation NuoCheckboardMesh


- (instancetype)initWithCommandQueue:(id<MTLCommandQueue>)commandQueue
{
    self = [super initWithCommandQueue:commandQueue];
    
    if (self)
    {
        [self setSampleCount:1];
        [self makePipelineAndSampler:MTLPixelFormatBGRA8Unorm
                 withFragementShader:@"fragment_checker" withBlendMode:kBlend_None];
    }
    
    return self;
}


@end
