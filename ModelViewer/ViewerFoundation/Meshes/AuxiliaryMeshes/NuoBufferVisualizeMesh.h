//
//  NuoBufferVisualizeMesh.h
//  ModelViewer
//
//  Created by Dong on 4/18/19.
//  Copyright © 2019 middleware. All rights reserved.
//

#import "NuoScreenSpaceMesh.h"
#import "NuoUniforms.h"


@interface NuoBufferVisualizeMesh : NuoScreenSpaceMesh


- (void)updateBuffer:(id<MTLBuffer>)buffer withRange:(const NuoRangeUniform&)range;



@end


