//
//  NuoMeshAnimation.h
//  ModelViewer
//
//  Created by dfeng on 2/2/17.
//  Copyright © 2017 middleware. All rights reserved.
//

#import <Cocoa/Cocoa.h>

#include "NuoMeshRotation.h"


@class NuoLua;
@class NuoMesh;



@interface NuoMeshAnimation : NSObject

@property (nonatomic, strong) NSString* animationName;

@property (nonatomic, strong) NSArray<NuoMesh*>* mesh;
@property (nonatomic, assign) NuoMeshRotation animationEndPoint;


- (void)importAnimation:(NuoLua*)lua forMesh:(NSArray<NuoMesh*>*)mesh;
- (void)setProgress:(float)progress;


@end



