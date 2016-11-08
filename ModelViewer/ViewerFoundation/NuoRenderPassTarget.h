//
//  NuoRenderTarget.h
//  ModelViewer
//
//  Created by middleware on 11/7/16.
//  Copyright © 2016 middleware. All rights reserved.
//

#import <Foundation/Foundation.h>

#import <Metal/Metal.h>



@interface NuoRenderPassTarget : NSObject


@property (nonatomic, weak) id<MTLDevice> device;

@property (nonatomic, assign) uint sampleCount;
@property (nonatomic, assign) CGSize drawableSize;

/**
 *  the texture that holds the rendered pixels of the current pass
 */
@property (nonatomic, strong) id<MTLTexture> targetTexture;

/**
 *  whether the target texture is managed by the render-pass itself
 *  or by external (e.g. the drawable of a Metal view)
 */
@property (nonatomic, assign) BOOL manageTargetTexture;

@property (nonatomic, assign) MTLClearColor clearColor;

- (void)makeTextures;
- (MTLRenderPassDescriptor *)currentRenderPassDescriptor;

@end
