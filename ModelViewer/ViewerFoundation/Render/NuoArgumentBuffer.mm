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
    unsigned long _bufferItemLength;
    
    NSString* _name;
}



- (instancetype)initWithName:(NSString*)name
{
    self = [super init];
    
    if (self)
    {
        _usages = [NSMutableArray new];
        _index = -1;
        _bufferItemLength = 0;
        
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


- (void)encodeWith:(NuoComputeEncoder*)computeEncoder forIndex:(int)index withSize:(uint)size
{
    // should be encoded for only once
    assert(_index == -1);
    
    id<MTLArgumentEncoder> encoder = [computeEncoder.pipeline argumentEncoder:index];
    
    _bufferItemLength = encoder.encodedLength;
    _buffer = [encoder.device newBufferWithLength:_bufferItemLength * size options:0];
    _buffer.label = _name;
    
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



- (void)encodeItem:(uint)index
{
    [_encoder setArgumentBuffer:_buffer offset:index * _bufferItemLength];
}

@end






@implementation NuoArgumentUsage


@end
