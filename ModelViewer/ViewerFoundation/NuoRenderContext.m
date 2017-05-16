//
//  RenderContext.m
//  ModelViewer
//
//  Created by middleware on 5/14/17.
//  Copyright © 2017 middleware. All rights reserved.
//

#import "NuoRenderContext.h"



@implementation NuoRenderContext

- (instancetype)initWithRenderPass:(id<MTLRenderCommandEncoder>)renderPass
{
    self = [super init];
    if (self)
    {
        self.renderPass = renderPass;
    }
    
    return self;
}

@end
