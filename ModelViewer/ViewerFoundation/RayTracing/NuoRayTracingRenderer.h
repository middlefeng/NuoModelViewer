//
//  NuoRayTracingRenderer.h
//  ModelViewer
//
//  Created by middleware on 6/11/18.
//  Copyright © 2018 middleware. All rights reserved.
//

#import "NuoRenderPipelinePass.h"
#import "NuoMesh.h"



@class NuoRayAccelerateStructure;



@interface NuoRayTracingRenderer : NuoRenderPipelinePass

@property (nonatomic, assign) CGFloat fieldOfView;

@property (nonatomic, weak) NuoMesh* mesh;
@property (nonatomic, weak) NuoRayAccelerateStructure* rayStructure;


@end


