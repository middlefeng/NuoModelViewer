//
//  NuoMeshAnimation.h
//  ModelViewer
//
//  Created by dfeng on 2/2/17.
//  Copyright © 2017 middleware. All rights reserved.
//

#import <Cocoa/Cocoa.h>



@class NuoLua;
@class NuoMesh;
@class NuoMeshRotation;



@interface NuoMeshAnimation : NSObject

@property (nonatomic, strong) NSString* animationName;

@property (nonatomic, strong) NSArray<NuoMesh*>* mesh;
@property (nonatomic, assign) float progress;
@property (nonatomic, strong) NuoMeshRotation* animationEndPoint;


- (void)importAnimation:(NuoLua*)lua forMesh:(NSArray<NuoMesh*>*)mesh;


@end



