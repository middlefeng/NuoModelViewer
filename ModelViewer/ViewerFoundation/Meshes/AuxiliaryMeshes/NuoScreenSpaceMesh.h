//
//  NuoScreenSpaceMesh.h
//  ModelViewer
//
//  Created by Dong on 9/30/17.
//  Copyright © 2017 middleware. All rights reserved.
//

#import "NuoMesh.h"



typedef enum
{
    kBlend_Alpha,
    kBlend_Accumulate,
    
    /**
     *  this is to compensate some third-party, notably Photoshop, whose internal
     *  data representation is all non-multiplied alpha (so called straight alhpa)
     *  and which performs no other alpha-variant than regular alpha-blending (that
     *  is, always scaling down the source colors)
     *
     *  for such an app, the input file has to trick it that it is a premultiplied
     *  alpha, and the app will divide all colors by alpha. by doing so, it will cause
     *  divided by zero or overflowed quotation, and therefore loss color. so this
     *  mode generate what is lost in the above process.
     *
     *  this mode generates an image which can be used by Photoshop in the Add blend
     *  mode to compensate the lost by overflow (or divided by zero).
     */
    kBlend_AlphaOverflow,
    
    kBlend_None
}
ScreenSpaceBlendMode;


@interface NuoScreenSpaceMesh : NuoMesh


@property (nonatomic, weak) id<MTLSamplerState> samplerState;


- (instancetype)initWithCommandQueue:(id<MTLCommandQueue>)commandQueue;


- (void)makePipelineAndSampler:(MTLPixelFormat)pixelFormat
           withFragementShader:(NSString*)shaderName
                 withBlendMode:(ScreenSpaceBlendMode)mode;


@end
