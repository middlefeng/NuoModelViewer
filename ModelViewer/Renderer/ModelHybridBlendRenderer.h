//
//  ModelHybridBlendRenderer.h
//  ModelViewer
//
//  Created by middleware on 8/3/19.
//  Copyright © 2019 middleware. All rights reserved.
//

#import "NuoRenderPipelinePass.h"
#import "NuoIlluminationMesh.h"



@class ModelDirectLighting;



@interface ModelHybridBlendRenderer : NuoRenderPass


@property (nonatomic, weak) NuoIlluminationTarget* illuminations;

@property (nonatomic, weak) id<MTLTexture> translucentMap;

@property (nonatomic, strong) NSArray<ModelDirectLighting*>* directLighting;


- (instancetype)initWithCommandQueue:(id<MTLCommandQueue>)commandQueue
                     withPixelFormat:(MTLPixelFormat)pixelFormat
                     withSampleCount:(uint)sampleCount;


@end


