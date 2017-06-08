//
//  BoardSettingPanel.h
//  ModelViewer
//
//  Created by middleware on 6/8/17.
//  Copyright © 2017 middleware. All rights reserved.
//

#import <Cocoa/Cocoa.h>

@interface NuoSheetPanel : NSPanel

@property (weak, nonatomic) NSWindow* rootWindow;
@property (strong, nonatomic) NSView* rootView;

@end
