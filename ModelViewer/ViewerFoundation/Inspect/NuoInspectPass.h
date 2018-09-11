//
//  NuoInspectPass.h
//  ModelViewer
//
//  Created by middleware on 9/11/18.
//  Copyright © 2018 middleware. All rights reserved.
//

#import "NuoRenderPipelinePass.h"



@interface NuoInspectPass : NuoRenderPipelinePass

@property (nonatomic, weak) id<MTLTexture> inspectedTexture;

@end


