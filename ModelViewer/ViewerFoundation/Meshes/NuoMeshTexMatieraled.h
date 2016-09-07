//
//  NuoMeshTexMatieraled.h
//  ModelViewer
//
//  Created by dfeng on 9/7/16.
//  Copyright © 2016 middleware. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "NuoMeshTextured.h"




@interface NuoMeshTexMatieraled : NuoMeshTextured


- (instancetype)initWithDevice:(id<MTLDevice>)device
               withTexutrePath:(NSString*)texPath
         withCheckTransparency:(BOOL)check
            withVerticesBuffer:(void*)buffer withLength:(size_t)length
                   withIndices:(void*)indices withLength:(size_t)indicesLength;


@end
