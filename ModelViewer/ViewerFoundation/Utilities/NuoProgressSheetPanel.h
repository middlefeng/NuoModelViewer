//
//  NuoProgressSheetPanel.h
//  ModelViewer
//
//  Created by Dong on 12/10/17.
//  Copyright © 2017 middleware. All rights reserved.
//

#import <Cocoa/Cocoa.h>
#import "NuoTypes.h"



@interface NuoProgressSheetPanel : NSPanel

@property (nonatomic, assign) float progress;

- (void)performInBackground:(NuoProgressIndicatedFunction)backgroundFunc
                 withWindow:(NSWindow*)rootWindow
             withCompletion:(NuoSimpleFunction)completion;

@end
