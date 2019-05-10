//
//  NuoShaderLibrary.m
//  ModelViewer
//
//  Created by Dong on 5/10/19.
//  Copyright © 2019 middleware. All rights reserved.
//

#import "NuoShaderLibrary.h"



@interface KeyDevice : NSObject<NSCopying>;
@property (nonatomic) id<MTLDevice> device;
@end

@implementation KeyDevice
- (id)copyWithZone:(nullable NSZone *)zone
{
    KeyDevice* newDevice = [KeyDevice new];
    newDevice.device = _device;
    return newDevice;
}
@end



static NSMutableDictionary<KeyDevice*, NuoShaderLibrary*>* defaultLibraries = nil;




@implementation NuoShaderLibrary
{
    id<MTLLibrary> _library;
}



+ (NuoShaderLibrary*)defaultLibraryWithDevice:(id<MTLDevice>)device
{
    if (!defaultLibraries)
        defaultLibraries = [[NSMutableDictionary alloc] init];
    
    KeyDevice* key = [KeyDevice new];
    key.device = device;
    
    NuoShaderLibrary* library = defaultLibraries[key];
    if (!library)
    {
        library = [[NuoShaderLibrary alloc] initWithLibrary:[device newDefaultLibrary]];
        [defaultLibraries setObject:library forKey:key];
    }
    
    return library;
}


- (instancetype)initWithLibrary:(id<MTLLibrary>)library
{
    self = [super init];
    if (self)
        _library = library;
    
    return self;
}


@end
