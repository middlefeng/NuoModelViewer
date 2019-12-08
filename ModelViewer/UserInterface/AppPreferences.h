//
//  AppPreferences.h
//  ModelViewer
//
//  Created by Dong on 11/27/19.
//  Copyright © 2019 middleware. All rights reserved.
//

#import <AppKit/AppKit.h>

#import "NuoWindow.h"
#import "ModelViewConfiguration.h"


@interface AppPreferences : NuoWindow

@property (nonatomic, weak) ModelViewConfiguration* configuration;

- (void)locateRelativeTo:(NSWindow*)window;

@end


