//
//  NuoShadowMapTarget.h
//  ModelViewer
//
//  Created by middleware on 1/16/17.
//  Copyright © 2017 middleware. All rights reserved.
//

#import <Foundation/Foundation.h>

#import <Metal/Metal.h>



@interface NuoShadowMapTarget : NSObject


@property (nonatomic, weak) id<MTLDevice> device;

@property (nonatomic, assign) uint sampleCount;
@property (nonatomic, assign) CGSize drawableSize;

/**
 *  the texture that holds the shadow map
 */
@property (nonatomic, strong) id<MTLTexture> targetTexture;

@property (nonatomic, strong) NSString* name;

- (void)makeTextures;
- (MTLRenderPassDescriptor *)currentRenderPassDescriptor;

@end
