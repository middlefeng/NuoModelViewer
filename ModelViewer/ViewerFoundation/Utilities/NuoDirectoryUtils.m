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
static char* pathForConfigureFileBuffer = 0;
static char* pathForOptionConfigureFileBuffer = 0;


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
    
    if (![fileManager fileExistsAtPath:path])
        [fileManager createDirectoryAtPath:path withIntermediateDirectories:YES attributes:nil error:nil];
    
    return pathForDocumentBuffer;
}



const char* pathForConfigureFile(void)
{
    if (pathForConfigureFileBuffer)
        return pathForConfigureFileBuffer;
    
    const char* pathCh = pathForDocument();
    NSString* path = [NSString stringWithFormat:@"%s/%s", pathCh, "configuration.cfg"];
    
    size_t size = path.length;
    pathForConfigureFileBuffer = malloc(size + 1);
    pathForConfigureFileBuffer[size] = 0;
    
    strcpy(pathForConfigureFileBuffer, path.UTF8String);
    
    return pathForConfigureFileBuffer;
}


const char* pathForOptionConfigureFile(void)
{
    if (pathForOptionConfigureFileBuffer)
        return pathForOptionConfigureFileBuffer;
    
    const char* pathCh = pathForDocument();
    NSString* path = [NSString stringWithFormat:@"%s/%s", pathCh, "optionConfiguration.cfg"];
    
    size_t size = path.length;
    pathForOptionConfigureFileBuffer = malloc(size + 1);
    pathForOptionConfigureFileBuffer[size] = 0;
    
    strcpy(pathForOptionConfigureFileBuffer, path.UTF8String);
    
    return pathForOptionConfigureFileBuffer;
}



void clearCategoryInDocument(const char* category)
{
    const char* pathCh = pathForDocument();
    
    NSString* path = [NSString stringWithFormat:@"%s/%s", pathCh, category];
    NSFileManager* fileManager = [NSFileManager defaultManager];
    
    [fileManager removeItemAtPath:path error:nil];
}

