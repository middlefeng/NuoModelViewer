//
//  NuoShadowMapTarget.h
//  ModelViewer
//
//  Created by middleware on 1/16/17.
//  Copyright © 2017 middleware. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <Metal/Metal.h>

#import "NuoRenderPassTarget.h"



@interface NuoShadowMapTarget : NuoRenderPassTarget


@property (nonatomic, readonly) id<MTLTexture> shadowMap1;


- (void)makeTextures;
- (MTLRenderPassDescriptor *)currentRenderPassDescriptor;

@end
