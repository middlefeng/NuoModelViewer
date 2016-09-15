//
//  NuoModelLoader.h
//  ModelViewer
//
//  Created by middleware on 8/26/16.
//  Copyright © 2016 middleware. All rights reserved.
//

#import <Foundation/Foundation.h>


@class NuoMesh;


@interface NuoModelLoader : NSObject

- (void)loadModel:(NSString*)path;
- (NSArray<NuoMesh*>*)createMeshsWithType:(NSString*)type
                               withDevice:(id<MTLDevice>)device;


@end
