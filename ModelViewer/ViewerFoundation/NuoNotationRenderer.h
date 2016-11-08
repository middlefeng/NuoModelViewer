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

- (instancetype)initWithDevice:(id<MTLDevice>)device
              withDrawableSize:(CGSize)drawableSize;

@end
