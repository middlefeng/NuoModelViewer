//
//  NuoModelLoader.h
//  ModelViewer
//
//  Created by middleware on 8/26/16.
//  Copyright © 2016 middleware. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <Metal/Metal.h>
#import "NuoTypes.h"


@class NuoMeshCompound;
@class NuoMeshOption;


@interface NuoModelLoader : NSObject

- (void)loadModel:(NSString*)path;


/**
 *  Create a renderable GPU mesh. A GPU mesh consists of the continuous buffer where the vertex data
 *  is stored, the associated textures, and the associated pipeline state used for rendering.
 */
- (NuoMeshCompound*)createMeshsWithOptions:(NuoMeshOption*)loadOption
                                withDevice:(id<MTLDevice>)device
                          withCommandQueue:(id<MTLCommandQueue>)commandQueue;


@end
