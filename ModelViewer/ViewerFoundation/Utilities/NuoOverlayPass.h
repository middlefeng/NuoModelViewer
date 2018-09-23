//
//  NuoOverlayPass.h
//  ModelViewer
//
//  Created by middleware on 8/7/18.
//  Copyright © 2018 middleware. All rights reserved.
//

#import "NuoRenderPipelinePass.h"



@interface NuoOverlayPass : NuoRenderPipelinePass

@property (nonatomic, strong) id<MTLTexture> overlay;

@end


