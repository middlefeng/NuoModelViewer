//
//  NuoArgumentBuffer.m
//  ModelViewer
//
//  Created by Dong on 7/10/19.
//  Copyright © 2019 middleware. All rights reserved.
//

#import "NuoArgumentBuffer.h"
#import "NuoComputeEncoder.h"



@implementation NuoArgumentBuffer
{
    id<MTLBuffer> _buffer;
    id<MTLArgumentEncoder> _encoder;
    NSMutableArray<NuoArgumentUsage*>* _usages;
    
    NSString* _name;
}



- (instancetype)initWithName:(NSString*)name
{
    self = [super init];
    
    if (self)
    {
        _usages = [NSMutableArray new];
        _index = -1;
        
        _name = name;
    }
    
    return self;
}


- (id<MTLBuffer>)buffer
{
    return _buffer;
}


- (NSArray<NuoArgumentUsage*>*)argumentsUsage
{
    return _usages;
}


- (void)encodeWith:(NuoComputePipeline*)pipeline forIndex:(int)index;
{
    // should be encoded for only once
    assert(_index == -1);
    
    id<MTLArgumentEncoder> encoder = [pipeline argumentEncoder:index];
    
    _buffer = [encoder.device newBufferWithLength:encoder.encodedLength options:0];
    _buffer.label = _name;
    
    [encoder setArgumentBuffer:_buffer offset:0];
    _encoder = encoder;
    _index = index;
}


- (void)setBuffer:(id<MTLBuffer>)buffer for:(MTLResourceUsage)usage atIndex:(uint)index
{
    [_encoder setBuffer:buffer offset:0 atIndex:index];
    
    NuoArgumentUsage* usageEntry = [NuoArgumentUsage new];
    usageEntry.argument = buffer;
    usageEntry.usage = usage;
    
    [_usages addObject:usageEntry];
}


- (void)setTexture:(id<MTLTexture>)texture for:(MTLResourceUsage)usage atIndex:(uint)index
{
    [_encoder setTexture:texture atIndex:index];
    
    NuoArgumentUsage* usageEntry = [NuoArgumentUsage new];
    usageEntry.argument = texture;
    usageEntry.usage = usage;
    
    [_usages addObject:usageEntry];
}


- (void)setInt:(uint32_t)value atIndex:(uint)index
{
    uint32_t* addr = (uint32_t*)[_encoder constantDataAtIndex:index];
    *addr = value;
}



@end






@implementation NuoArgumentUsage


@end
