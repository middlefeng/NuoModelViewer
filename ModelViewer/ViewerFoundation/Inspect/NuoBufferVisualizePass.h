//
//  NuoBufferVisualizePass.h
//  ModelViewer
//
//  Created by Dong on 4/18/19.
//  Copyright © 2019 middleware. All rights reserved.
//

#import "NuoRenderPipelinePass.h"
#import "NuoUniforms.h"


@interface NuoBufferVisualizePass : NuoRenderPipelinePass


@property (nonatomic, weak) id<MTLBuffer> inspectedBuffer;
@property (nonatomic, assign) NuoRangeUniform insepectedRange;


@end


