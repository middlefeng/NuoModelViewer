//
//  NuoModelLoader.h
//  ModelViewer
//
//  Created by middleware on 8/26/16.
//  Copyright © 2016 middleware. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "NuoTypes.h"


@class NuoMesh;
@class NuoMeshOption;


@interface NuoModelLoader : NSObject

- (void)loadModel:(NSString*)path;


/**
 *  Create a renderable GPU mesh. A GPU mesh consists of the continuous buffer where the vertex data
 *  is stored, the associated textures, and the associated pipeline state used for rendering.
 */
- (NSArray<NuoMesh*>*)createMeshsWithOptions:(NuoMeshOption*)loadOption
                                  withDevice:(id<MTLDevice>)device;


@end
