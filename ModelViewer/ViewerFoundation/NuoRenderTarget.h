//
//  NuoRenderTarget.h
//  ModelViewer
//
//  Created by middleware on 11/7/16.
//  Copyright © 2016 middleware. All rights reserved.
//

#import <Foundation/Foundation.h>

#import <Metal/Metal.h>



@interface NuoRenderTarget : NSObject


@property (nonatomic, assign) uint sampleCount;
@property (nonatomic, weak) id<MTLDevice> device;
@property (nonatomic, assign) CGSize drawableSize;
@property (nonatomic, strong) id<MTLTexture> targetTexture;

@property (nonatomic, assign) MTLClearColor clearColor;


- (void)makeTextures;
- (MTLRenderPassDescriptor *)currentRenderPassDescriptor;



@end
