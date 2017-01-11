//
//  ModelPartsList.h
//  ModelViewer
//
//  Created by middleware on 1/7/17.
//  Copyright © 2017 middleware. All rights reserved.
//

#import <Cocoa/Cocoa.h>


@class NuoMesh;



@interface ModelPartsPanel : NSView


- (void)setMesh:(NSArray<NuoMesh*>*)mesh;


@end
