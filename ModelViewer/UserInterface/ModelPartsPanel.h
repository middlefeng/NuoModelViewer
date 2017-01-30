//
//  ModelPartsList.h
//  ModelViewer
//
//  Created by middleware on 1/7/17.
//  Copyright © 2017 middleware. All rights reserved.
//

#import <Cocoa/Cocoa.h>


@class NuoMesh;
@protocol ModelOptionUpdate;
@protocol ModelPanelUpdate;



@interface ModelPartsPanel : NSView


@property (nonatomic, weak) id<ModelOptionUpdate> optionUpdateDelegate;
@property (nonatomic, weak) id<ModelPanelUpdate> panelUpdateDelegate;

- (void)setMesh:(NSArray<NuoMesh*>*)mesh;


@end
