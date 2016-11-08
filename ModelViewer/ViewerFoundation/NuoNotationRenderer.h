//
//  NuoNotationRenderer.h
//  ModelViewer
//
//  Created by middleware on 11/6/16.
//  Copyright © 2016 middleware. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <Metal/Metal.h>

#import "NuoMetalView.h"
#import "NuoRenderTarget.h"


@interface NuoNotationRenderer : NuoRenderTarget <NuoMetalViewDelegate>

@property (nonatomic, weak) id<MTLTexture> sourceTexture;

- (instancetype)initWithDevice:(id<MTLDevice>)device;

@end
