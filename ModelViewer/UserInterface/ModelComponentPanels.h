//
//  ModelComponentPanels.h
//  ModelViewer
//
//  Created by middleware on 1/29/17.
//  Copyright © 2017 middleware. All rights reserved.
//

#import <Cocoa/Cocoa.h>



@protocol ModelOptionUpdate;
@class NuoMesh;



@interface ModelComponentPanels : NSObject



@property (nonatomic, weak) NSView* containerView;
@property (nonatomic, weak) id<ModelOptionUpdate> modelOptionDelegate;


- (void)containerViewResized;

- (void)setMesh:(NSArray<NuoMesh*>*)mesh;
- (void)setHidden:(BOOL)hidden;

- (void)addPanels;


@end
