//
//  NuoRenderPipelinePass.h
//  ModelViewer
//
//  Created by middleware on 1/17/17.
//  Copyright © 2017 middleware. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "NuoRenderPass.h"



@interface NuoRenderPipelinePass : NuoRenderPass


/**
 *  data exchange with adjecent passes
 */
@property (nonatomic, weak) id<MTLTexture> sourceTexture;

@end
