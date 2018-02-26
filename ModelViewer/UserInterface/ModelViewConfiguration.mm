//
//  ModelViewConfiguration.m
//  ModelViewer
//
//  Created by Dong on 2/25/18.
//  Copyright © 2018 middleware. All rights reserved.
//

#import "ModelViewConfiguration.h"
#import "NuoLua.h"

#include "NuoTableExporter.h"


@implementation ModelViewConfiguration

- (instancetype)initWithFile:(NSString*)path
{
    self = [super init];
    return self;
}


- (void)save
{
    NuoTableExporter exporter;
    
    exporter.StartTable();
    
    exporter.StartEntry("windowFrame");
    exporter.StartTable();
    
    {
        exporter.StartEntry("x");
        exporter.SetEntryValueFloat(_windowFrame.origin.x);
        exporter.EndEntry(false);
        
        exporter.StartEntry("y");
        exporter.SetEntryValueFloat(_windowFrame.origin.y);
        exporter.EndEntry(false);
        
        exporter.StartEntry("w");
        exporter.SetEntryValueFloat(_windowFrame.size.width);
        exporter.EndEntry(false);
        
        exporter.StartEntry("h");
        exporter.SetEntryValueFloat(_windowFrame.size.height);
        exporter.EndEntry(false);
    }
    
    exporter.EndTable();
    exporter.EndEntry(true);
    
    exporter.StartEntry("device");
    exporter.SetEntryValueString(_deviceName.UTF8String);
    exporter.EndEntry(true);
    
    exporter.EndTable();
}


@end
