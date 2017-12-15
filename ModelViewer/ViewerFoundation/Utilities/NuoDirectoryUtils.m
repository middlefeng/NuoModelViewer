//
//  NuoDirectoryUtils.cpp
//  ModelViewer
//
//  Created by Dong on 12/14/17.
//  Copyright © 2017 middleware. All rights reserved.
//

#include "NuoDirectoryUtils.h"

#import <Foundation/Foundation.h>


static char* pathForDocumentBuffer = 0;


const char* pathForDocument(void)
{
    if (pathForDocumentBuffer)
        return pathForDocumentBuffer;
    
    NSFileManager* fileManager = [NSFileManager defaultManager];
    NSArray<NSURL*>* urls = [fileManager URLsForDirectory:NSDocumentDirectory inDomains:NSUserDomainMask];
    NSString* path = urls[0].path;
    
    path = [path stringByAppendingPathComponent:@"NuoModelViewer"];
    
    size_t size = path.length;
    pathForDocumentBuffer = malloc(size + 1);
    pathForDocumentBuffer[size] = 0;
    
    strcpy(pathForDocumentBuffer, path.UTF8String);
    
    return pathForDocumentBuffer;
}

