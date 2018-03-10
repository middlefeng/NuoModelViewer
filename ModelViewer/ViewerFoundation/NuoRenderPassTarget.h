//
//  NuoRenderTarget.h
//  ModelViewer
//
//  Created by middleware on 11/7/16.
//  Copyright © 2016 middleware. All rights reserved.
//

#import <Foundation/Foundation.h>

#import <Metal/Metal.h>


@class NuoClearMesh;


@interface NuoRenderPassTarget : NSObject


@property (nonatomic, strong) NSString* name;


@property (nonatomic, weak) id<MTLDevice> device;

@property (nonatomic, assign) uint sampleCount;
@property (nonatomic, assign) CGSize drawableSize;

/**
 *  the texture that holds the rendered pixels of the current pass
 */
@property (nonatomic, strong) id<MTLTexture> targetTexture;

@property (nonatomic, strong) id<MTLTexture> depthTexture;

/**
 *  whether the target texture is managed by the render-pass itself
 *  or by external (e.g. the drawable of a Metal view)
 */
@property (nonatomic, assign) BOOL manageTargetTexture;

/**
 *  whether the target be read back to the CPU side,
 *  ignored if manageTargetTexture is NO because in that case the texture is for
 *  screen display (amature to readback on-screen texture) 
 */
@property (nonatomic, assign) BOOL sharedTargetTexture;

@property (nonatomic, assign) MTLPixelFormat targetPixelFormat;

@property (nonatomic, assign) MTLClearColor clearColor;
@property (nonatomic, strong) NuoClearMesh* textureMesh;

/**
 *  overriden by subclass, called on the drawable-size setting
 */
- (void)makeTextures;

- (id<MTLRenderCommandEncoder>)retainRenderPassEndcoder:(id<MTLCommandBuffer>)commandBuffer;
- (void)releaseRenderPassEndcoder;

- (void)clearAction:(id<MTLRenderCommandEncoder>)encoder;

- (MTLRenderPassDescriptor *)currentRenderPassDescriptor;

@end
