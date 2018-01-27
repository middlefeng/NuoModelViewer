//
//  NuoMeshBounds.h
//  ModelViewer
//
//  Created by Dong on 1/25/18.
//  Copyright © 2018 middleware. All rights reserved.
//

#import <Foundation/Foundation.h>

#include "NuoBounds.h"


@interface NuoMeshBounds : NSObject

- (struct NuoBoundsBase*)boundingBox;

@end
