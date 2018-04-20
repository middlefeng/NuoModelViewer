//
//  ModelSelectionRenderer.m
//  ModelViewer
//
//  Created by Dong on 3/27/18.
//  Copyright © 2018 middleware. All rights reserved.
//

#import "ModelSelectionRenderer.h"



@implementation ModelSelectionRenderer


- (void)drawWithCommandBuffer:(id<MTLCommandBuffer>)commandBuffer withInFlightIndex:(unsigned int)inFlight
{
    id<MTLRenderCommandEncoder> renderPass = [self retainDefaultEncoder:commandBuffer];
    
    renderPass.label = @"Selection";
    
    [super drawWithCommandBuffer:commandBuffer withInFlightIndex:inFlight];
    [self releaseDefaultEncoder];
}


@end
