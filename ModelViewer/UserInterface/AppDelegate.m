//
//  AppDelegate.m
//  NuoModelViewer
//
//  Created by middleware on 8/13/16.
//  Copyright © 2017 middleware. All rights reserved.
//

#import "AppDelegate.h"
#import "NuoDirectoryUtils.h"



@interface AppDelegate ()

@property (weak) IBOutlet NSWindow *window;

@end




@implementation AppDelegate

- (void)applicationDidFinishLaunching:(NSNotification *)aNotification
{
}

- (void)applicationWillTerminate:(NSNotification *)aNotification
{
    clearCategoryInDocument("packaged_load");
}

@end
