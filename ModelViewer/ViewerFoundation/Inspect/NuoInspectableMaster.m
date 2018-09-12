//
//  NuoInspectableMaster.m
//  ModelViewer
//
//  Created by middleware on 9/7/18.
//  Copyright © 2018 middleware. All rights reserved.
//

#import "NuoInspectableMaster.h"



static NuoInspectableMaster* sInspectableMaster = nil;


NSString* const kInspectable_Immediate = @"inspectable_immediate";
NSString* const kInspectable_ImmediateAlpha = @"inspectable_immediateAlpha";
NSString* const kInspectable_Ambient = @"inspectable_ambient";
NSString* const kInspectable_Shadow0 = @"inspectable_shadow0";
NSString* const kInspectable_Shadow1 = @"inspectable_shadow1";


@implementation NuoInspectable


+ (NuoInspectable*)inspectableWithTitle:(NSString*)title withMean:(NSString*)mean
{
    NuoInspectable* inspect = [NuoInspectable new];
    inspect.displayTitle = title;
    inspect.inspectingMean = mean;
    
    return inspect;
}


@end


@implementation NuoInspectableMaster

+ (NuoInspectableMaster*)sharedMaster
{
    if (!sInspectableMaster)
    {
        sInspectableMaster = [NuoInspectableMaster new];
    }
    
    return sInspectableMaster;
}


+ (NSDictionary<NSString*, NuoInspectable*>*)inspectableList
{
    return @{ kInspectable_Immediate: [NuoInspectable inspectableWithTitle:@"Immediate" withMean:nil],
              kInspectable_ImmediateAlpha: [NuoInspectable inspectableWithTitle:@"Immediate Alpha" withMean:@"fragment_alpha"],
              kInspectable_Ambient: [NuoInspectable inspectableWithTitle:@"Ambient" withMean:nil],
              kInspectable_Shadow0: [NuoInspectable inspectableWithTitle:@"Shadow [0]" withMean:nil],
              kInspectable_Shadow1: [NuoInspectable inspectableWithTitle:@"Shadow [1]" withMean:nil] };
}


- (instancetype)init
{
    self = [super init];
    
    if (self)
    {
        _inspectables = [NSMutableDictionary new];
    }
    
    return self;
}



- (NuoInspectable*)inspectableForName:(NSString*)name create:(BOOL)create
{
    NuoInspectable* inspectable = [_inspectables objectForKey:name];
    
    if (!inspectable && create)
    {
        inspectable = [NuoInspectableMaster inspectableList][name];
        [_inspectables setObject:inspectable forKey:name];
    }
    
    return inspectable;
}


- (void)updateTexture:(id<MTLTexture>)texture forName:(NSString*)name
{
    NuoInspectable* inspectable = [self inspectableForName:name create:NO];
    inspectable.inspectedTexture = texture;
}



- (void)removeInspectorForName:(NSString*)name
{
    NuoInspectable* inspectable = [[NuoInspectable alloc] init];
    inspectable.inspector = [self inspectableForName:name create:NO].inspector;
    
    [_inspectables removeObjectForKey:name];
}


- (NuoInspectable*)setInspector:(id<NuoInspector>)inspector forName:(NSString*)name;
{
    NuoInspectable* inspectable = [self inspectableForName:name create:YES];
    inspectable.inspector = inspector;
    
    return inspectable;
}



- (void)inspect
{
    for (NSString* inspectable in _inspectables)
    {
        id<MTLTexture> inspectedTexture = _inspectables[inspectable].inspectedTexture;
        if (inspectedTexture)
            [_inspectables[inspectable].inspector setInspectAspectRatio:(float)[inspectedTexture width] / (float)[inspectedTexture height]];
        
        [_inspectables[inspectable].inspector inspect];
    }
}


@end
