//
//  NuoMeshBounds.h
//  ModelViewer
//
//  Created by Dong on 1/25/18.
//  Copyright © 2018 middleware. All rights reserved.
//

#import <Foundation/Foundation.h>

#include "NuoBounds.h"


/**
 *  A wrapper that minimizes the spread of C++.
 */

@interface NuoMeshBounds : NSObject

- (struct NuoBounds*)boundingBox;
- (struct NuoSphere*)boundingSphere;

@end
