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
- (NSArray<NuoMesh*>*)createMeshsWithOptions:(NuoMeshOption*)loadOption
                                  withDevice:(id<MTLDevice>)device;


@end
