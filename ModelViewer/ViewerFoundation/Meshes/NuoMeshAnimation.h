//
//  NuoMeshAnimation.h
//  ModelViewer
//
//  Created by dfeng on 2/2/17.
//  Copyright © 2017 middleware. All rights reserved.
//

#import <Cocoa/Cocoa.h>



@class NuoMesh;
@class NuoMeshRotation;



@interface NuoMeshAnimation : NSObject


@property (nonatomic, strong) NSArray<NuoMesh*>* mesh;
@property (nonatomic, assign) float progress;
@property (nonatomic, strong) NuoMeshRotation* animationEndPoint;


@end
