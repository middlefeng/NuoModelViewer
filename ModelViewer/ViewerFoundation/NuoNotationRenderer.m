//
//  NuoNotationRenderer.m
//  ModelViewer
//
//  Created by middleware on 11/6/16.
//  Copyright © 2016 middleware. All rights reserved.
//

#import "NuoNotationRenderer.h"






@implementation NuoNotationRenderer


- (instancetype)initWithDevice:(id<MTLDevice>)device withDrawableSize:(CGSize)drawableSize
{
    self = [super init];
    if (self)
    {
        self.device = device;
        self.drawableSize = drawableSize;
    }
    
    return self;
}


- (void)drawInView:(NuoMetalView *)view withCommandBuffer:(id<MTLCommandBuffer>)commandBuffer
{
    
}


@end
