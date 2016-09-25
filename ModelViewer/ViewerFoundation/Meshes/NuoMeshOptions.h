//
//  NuoMeshOptions.h
//  ModelViewer
//
//  Created by middleware on 9/15/16.
//  Copyright © 2016 middleware. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "NuoTypes.h"



@interface NuoMeshOption : NSObject

@property (nonatomic, assign) BOOL textured;
@property (nonatomic, assign) BOOL textureEmbeddingMaterialTransparency;
@property (nonatomic, assign) BOOL basicMaterialized;

@property (nonatomic, assign) BOOL combineShapes;

@end
