//
//  NuoInspectWindow.h
//  ModelViewer
//
//  Created by middleware on 9/7/18.
//  Copyright © 2018 middleware. All rights reserved.
//

#import "NuoWindow.h"
#import "NuoInspectableMaster.h"



@interface NuoInspectWindow : NuoWindow < NuoInspector >

- (instancetype)initWithDevice:(id<MTLDevice>)device forName:(NSString*)name;

- (void)inspect;

@end


