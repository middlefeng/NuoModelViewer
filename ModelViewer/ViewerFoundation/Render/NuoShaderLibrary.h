//
//  NuoShaderLibrary.h
//  ModelViewer
//
//  Created by Dong on 5/10/19.
//  Copyright © 2019 middleware. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <Metal/Metal.h>


@interface NuoShaderLibrary : NSObject


+ (NuoShaderLibrary*)defaultLibraryWithDevice:(id<MTLDevice>)device;


@end


